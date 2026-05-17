// lib/presentation/screens/location/location_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atmos/core/constants/app_constants.dart';
import 'package:atmos/core/theme/app_theme.dart';
import 'package:atmos/core/utils/weather_utils.dart';
import 'package:atmos/data/models/weather_model.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/presentation/bloc/weather/weather_bloc.dart';
import 'package:atmos/presentation/screens/main_shell.dart';
import 'package:dio/dio.dart';

// ─── Recent history key ───────────────────────────────────────────────────────

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  List<SavedLocation> _saved = [];
  List<GeocodingResult> _searchResults = [];
  List<GeocodingResult> _recentLocations = [];
  final Map<String, OpenMeteoModel?> _weatherCache = {};

  bool _searching = false;
  bool _loading = true;
  bool _showResults = false;

  WeatherRepository? _repo;

  @override
  void initState() {
    super.initState();
    _initRepo();
  }

  Future<void> _initRepo() async {
    final prefs = await SharedPreferences.getInstance();
    _repo = WeatherRepository(
      dio: Dio(BaseOptions(connectTimeout: const Duration(seconds: 12))),
      prefs: prefs,
    );
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Saved locations
    final raw = prefs.getString(AppConstants.savedLocationsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _saved = list
            .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final dedupedSaved = _dedupeSaved(_saved);
    if (dedupedSaved.length != _saved.length) {
      _saved = dedupedSaved;
      await prefs.setString(
        AppConstants.savedLocationsKey,
        jsonEncode(_saved.map((s) => s.toJson()).toList()),
      );
    }

    // Recent history
    if (_repo != null) {
      _recentLocations = _repo!.getRecentLocations(max: 8);
    }

    final savedKeys = _saved.map((s) => _locKey(s.lat, s.lon)).toSet();
    final dedupedRecent = _dedupeRecent(_recentLocations, savedKeys);
    if (dedupedRecent.length != _recentLocations.length) {
      _recentLocations = dedupedRecent;
      await _persistRecent(dedupedRecent);
    }

    if (mounted) setState(() => _loading = false);

    await _fetchWeatherForAll();
  }

  Future<void> _fetchWeatherForAll() async {
    if (_repo == null) return;
    final allLocs = [
      ..._saved.map(
        (s) => GeocodingResult(
          name: s.name,
          lat: s.lat,
          lon: s.lon,
          country: s.country,
          state: s.state,
        ),
      ),
      ..._recentLocations,
    ];

    for (final loc in allLocs) {
      final key = '${loc.lat}_${loc.lon}';
      if (_weatherCache.containsKey(key)) continue;
      try {
        final w =
            await _repo!.fetchOpenMeteoForecast(lat: loc.lat, lon: loc.lon);
        if (mounted) setState(() => _weatherCache[key] = w);
      } catch (_) {
        if (mounted) setState(() => _weatherCache[key] = null);
      }
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (_repo == null) return;
      final results = await _repo!.searchLocations(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showResults = true;
          _searching = false;
        });
      }
    });
  }

  // ─── Save location ─────────────────────────────────────────────────────────
  Future<void> _saveLocation(GeocodingResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final newLoc = SavedLocation(
      id: '${result.lat.toStringAsFixed(4)}_${result.lon.toStringAsFixed(4)}',
      name: result.name,
      country: result.country,
      state: result.state,
      lat: result.lat,
      lon: result.lon,
      isHome: _saved.isEmpty,
      savedAt: DateTime.now(),
    );
    if (_saved.any((s) => s.id == newLoc.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location already saved')),
        );
      }
      return;
    }
    _saved.add(newLoc);
    await prefs.setString(
      AppConstants.savedLocationsKey,
      jsonEncode(_saved.map((s) => s.toJson()).toList()),
    );
    await _addToRecent(result);
    if (mounted) {
      setState(() {});
      await _fetchWeatherForKey(result.lat, result.lon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} saved'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Set as current location ───────────────────────────────────────────────
  void _setAsCurrent(GeocodingResult result) {
    context.read<WeatherBloc>().add(
          FetchWeatherByCoords(
            lat: result.lat,
            lon: result.lon,
            cityName: result.name,
            countryCode: result.country,
            stateName: result.state,
            provinceName: result.admin2,
          ),
        );
    _addToRecent(result);
    _searchCtrl.clear();
    setState(() {
      _showResults = false;
      _searchResults = [];
    });
    _searchFocus.unfocus();

    // Navigate to Home tab
    final shell = context.findAncestorStateOfType<MainShellState>();
    shell?.navigateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing weather for ${result.name}'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Recent history ────────────────────────────────────────────────────────
  Future<void> _addToRecent(GeocodingResult result) async {
    if (_repo == null) return;
    await _repo!.addRecentLocation(result, max: 8);
    final savedKeys = _saved.map((s) => _locKey(s.lat, s.lon)).toSet();
    _recentLocations =
        _dedupeRecent(_repo!.getRecentLocations(max: 8), savedKeys);
    await _persistRecent(_recentLocations);
    if (mounted) setState(() {});
  }

  Future<void> _fetchWeatherForKey(double lat, double lon) async {
    if (_repo == null) return;
    final key = '${lat}_$lon';
    try {
      final w = await _repo!.fetchOpenMeteoForecast(lat: lat, lon: lon);
      if (mounted) setState(() => _weatherCache[key] = w);
    } catch (_) {}
  }

  // ─── Remove saved location ─────────────────────────────────────────────────
  Future<void> _removeLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _saved.removeWhere((s) => s.id == id);
    await prefs.setString(
      AppConstants.savedLocationsKey,
      jsonEncode(_saved.map((s) => s.toJson()).toList()),
    );
    if (mounted) setState(() {});
  }

  // ─── Set home ──────────────────────────────────────────────────────────────
  Future<void> _setHome(String id) async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < _saved.length; i++) {
      _saved[i] = _saved[i].copyWith(isHome: _saved[i].id == id);
    }
    await prefs.setString(
      AppConstants.savedLocationsKey,
      jsonEncode(_saved.map((s) => s.toJson()).toList()),
    );
    if (mounted) setState(() {});
  }

  // ─── Navigate to city weather ──────────────────────────────────────────────
  void _goToWeather(
    double lat,
    double lon,
    String name,
    String country, {
    String? state,
    String? admin2,
  }) {
    context.read<WeatherBloc>().add(
          FetchWeatherByCoords(
            lat: lat,
            lon: lon,
            cityName: name,
            countryCode: country,
            stateName: state,
            provinceName: admin2,
          ),
        );
    final shell = context.findAncestorStateOfType<MainShellState>();
    shell?.navigateTo(0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: BlocListener<WeatherBloc, WeatherState>(
        listener: (context, state) {
          if (state is WeatherLoaded || state is WeatherRefreshing) {
            _syncFromBloc(state);
          }
        },
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.skyGradient),
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                _searchFocus.unfocus();
                if (_searchCtrl.text.isEmpty) {
                  setState(() {
                    _showResults = false;
                    _searchResults = [];
                  });
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  Expanded(
                    child: _showResults
                        ? _buildSearchResults()
                        : _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryAccent,
                                ),
                              )
                            : BlocBuilder<WeatherBloc, WeatherState>(
                                builder: (context, state) {
                                  return _buildLocationList(state);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Locations',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              Text(
                '${_saved.length} saved cit${_saved.length == 1 ? 'y' : 'ies'}',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppColors.white60,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          color: AppColors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search city, zip code…',
          hintStyle:
              const TextStyle(color: AppColors.white40, fontFamily: 'Rajdhani'),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.white60),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.clear_rounded, color: AppColors.white60),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchResults = [];
                      _showResults = false;
                    });
                    _searchFocus.unfocus();
                  },
                )
              : _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white60,
                        ),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  // ─── Search results with set-current + save buttons ───────────────────────
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.white40, size: 52),
            SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                color: AppColors.white60,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final r = _searchResults[i];
        final alreadySaved = _saved.any(
          (s) => (s.lat - r.lat).abs() < 0.01 && (s.lon - r.lon).abs() < 0.01,
        );
        return _SearchResultCard(
          result: r,
          alreadySaved: alreadySaved,
          onSetCurrent: () => _setAsCurrent(r),
          onSave: alreadySaved ? null : () => _saveLocation(r),
        ).animate().fadeIn(duration: 250.ms, delay: (i * 40).ms);
      },
    );
  }

  // ─── Full location list ────────────────────────────────────────────────────
  Widget _buildLocationList(WeatherState blocState) {
    final currentLat = blocState is WeatherLoaded ? blocState.lat : null;
    final currentLon = blocState is WeatherLoaded ? blocState.lon : null;
    final currentCity = blocState is WeatherLoaded ? blocState.cityName : null;
    final currentCountry =
        blocState is WeatherLoaded ? blocState.countryCode : null;
    final currentState =
        blocState is WeatherLoaded ? blocState.stateName : null;
    final currentLabel = currentCity != null
        ? _formatCityState(currentCity, currentState)
        : null;
    final currentKey = currentLat != null ? '${currentLat}_$currentLon' : null;
    final currentWeather =
        currentKey != null ? _weatherCache[currentKey] : null;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.tempYellow,
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // ── Current GPS location ──────────────────────────────────────────
          if (currentLat != null) ...[
            const _SectionLabel(label: 'CURRENT LOCATION'),
            _CurrentLocationCard(
              cityName: currentLabel ?? 'Your Location',
              country: currentCountry ?? '',
              stateName: currentState,
              lat: currentLat,
              lon: currentLon!,
              weather: currentWeather,
              onTap: () => _goToWeather(
                currentLat,
                currentLon,
                currentCity ?? '',
                currentCountry ?? '',
                state: currentState,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
          ],

          // ── Saved locations ───────────────────────────────────────────────
          if (_saved.isNotEmpty) ...[
            const _SectionLabel(label: 'SAVED LOCATIONS'),
            ..._saved.asMap().entries.map((e) {
              final loc = e.value;
              final key = '${loc.lat}_${loc.lon}';
              return _SavedLocationCard(
                location: loc,
                weather: _weatherCache[key],
                onTap: () => _goToWeather(
                  loc.lat,
                  loc.lon,
                  loc.name,
                  loc.country,
                  state: loc.state,
                  admin2: loc.admin2,
                ),
                onDelete: () => _removeLocation(loc.id),
                onSetHome: () => _setHome(loc.id),
              ).animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms);
            }),
            const SizedBox(height: 16),
          ],

          // ── Recent locations ──────────────────────────────────────────────
          if (_recentLocations.isNotEmpty) ...[
            const _SectionLabel(label: 'RECENTLY VIEWED'),
            ..._recentLocations.asMap().entries.map((e) {
              final r = e.value;
              final key = '${r.lat}_${r.lon}';
              return _RecentLocationCard(
                result: r,
                weather: _weatherCache[key],
                onTap: () => _goToWeather(
                  r.lat,
                  r.lon,
                  r.name,
                  r.country,
                  state: r.state,
                  admin2: r.admin2,
                ),
                onSave: _saved.any(
                  (s) =>
                      (s.lat - r.lat).abs() < 0.01 &&
                      (s.lon - r.lon).abs() < 0.01,
                )
                    ? null
                    : () => _saveLocation(r),
              ).animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms);
            }),
            const SizedBox(height: 16),
          ],

          // ── Empty state ───────────────────────────────────────────────────
          if (_saved.isEmpty && _recentLocations.isEmpty && currentLat == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      color: AppColors.white40,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No saved locations yet',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white60,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Search for a city above to get started',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 13,
                        color: AppColors.white40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _syncFromBloc(WeatherState blocState) async {
    if (_repo == null || !mounted) return;
    final recent = _repo!.getRecentLocations(max: 8);
    final savedKeys = _saved.map((s) => _locKey(s.lat, s.lon)).toSet();
    final dedupedRecent = _dedupeRecent(recent, savedKeys);
    _recentLocations = dedupedRecent;
    await _persistRecent(dedupedRecent);

    if (blocState is WeatherLoaded) {
      final loaded = blocState;
      final lat = loaded.lat;
      final lon = loaded.lon;
      final key = '${lat}_$lon';
      if (!_weatherCache.containsKey(key)) {
        await _fetchWeatherForKey(lat, lon);
      }
    } else if (blocState is WeatherRefreshing) {
      final refreshing = blocState;
      final lat = refreshing.lat;
      final lon = refreshing.lon;
      final key = '${lat}_$lon';
      if (!_weatherCache.containsKey(key)) {
        await _fetchWeatherForKey(lat, lon);
      }
    }

    if (mounted) setState(() {});
  }

  String _formatCityState(String city, String? state) {
    return LocationLabelFormatter.cityLine(city, state);
  }

  String _locKey(double lat, double lon) {
    return '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  }

  List<SavedLocation> _dedupeSaved(List<SavedLocation> saved) {
    final seen = <String>{};
    final result = <SavedLocation>[];
    for (final loc in saved) {
      if (!seen.add(loc.id)) continue;
      result.add(loc);
    }
    return result;
  }

  List<GeocodingResult> _dedupeRecent(
    List<GeocodingResult> recent,
    Set<String> savedKeys,
  ) {
    final seen = <String>{};
    final result = <GeocodingResult>[];
    for (final loc in recent) {
      // 2-decimal key (~1 km grid) prevents GPS-drift duplicates
      final roundedKey =
          '${loc.lat.toStringAsFixed(2)}_${loc.lon.toStringAsFixed(2)}';
      // Skip if already in saved locations (fuzzy match within ~1 km)
      final inSaved = savedKeys.any((sk) {
        final parts = sk.split('_');
        if (parts.length < 2) return false;
        final slat = double.tryParse(parts[0]) ?? 0;
        final slon = double.tryParse(parts[1]) ?? 0;
        return (slat - loc.lat).abs() < 0.01 && (slon - loc.lon).abs() < 0.01;
      });
      if (inSaved) continue;
      if (!seen.add(roundedKey)) continue;
      result.add(loc);
    }
    return result;
  }

  Future<void> _persistRecent(List<GeocodingResult> recent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.recentLocationsKey,
      jsonEncode(
        recent
            .map(
              (r) => {
                'name': r.name,
                'lat': r.lat,
                'lon': r.lon,
                'country': r.country,
                'state': r.state,
                'admin2': r.admin2,
              },
            )
            .toList(),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

// ─── Location label formatter ─────────────────────────────────────────────────
/// Centralised logic for turning raw geocoding fields into clean display labels.
///
/// Handles cases such as:
///   city="Tokyo", state="Tokyo"                    → "Tokyo"
///   city="Manila", state="National Capital Region" → "Manila, NCR"
///   city="Calauan", state="Calabarzon"             → "Calauan" (region too broad)
///   city="Lipa", state="Calabarzon", admin2="Batangas" → "Lipa, Batangas"
class LocationLabelFormatter {
  static const _phRegionMap = <String, String?>{
    'calabarzon': null,
    'ncr': 'NCR',
    'national capital region': 'NCR',
    'metro manila': 'NCR',
    'cordillera administrative region': 'CAR',
    'car': 'CAR',
    'ilocos region': 'Region I',
    'cagayan valley': 'Region II',
    'central luzon': 'Region III',
    'mimaropa': 'MIMAROPA',
    'bicol region': 'Bicol',
    'western visayas': 'W. Visayas',
    'central visayas': 'C. Visayas',
    'eastern visayas': 'E. Visayas',
    'zamboanga peninsula': 'Zamboanga',
    'northern mindanao': 'N. Mindanao',
    'davao region': 'Davao',
    'soccsksargen': 'SOCCSKSARGEN',
    'caraga': 'CARAGA',
    'barmm': 'BARMM',
    'bangsamoro': 'BARMM',
  };

  /// Builds the city-line label, e.g. "Lipa, Batangas" or "Tokyo".
  /// [admin2] is the finer province/district level field when the API exposes it.
  static String cityLine(String city, String? state, {String? admin2}) {
    final cityClean = city.trim();

    // Prefer admin2 (province) over state (region)
    if (admin2 != null && admin2.trim().isNotEmpty) {
      final a2 = admin2.trim();
      if (!_same(cityClean, a2)) return '$cityClean, $a2';
    }

    final stateClean = state?.trim() ?? '';
    if (stateClean.isEmpty) return cityClean;
    if (_same(cityClean, stateClean)) return cityClean;

    final mapped = _mapState(stateClean);
    if (mapped == null) return cityClean; // region too coarse
    return '$cityClean, $mapped';
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static String? _mapState(String state) {
    final key = state.trim().toLowerCase();
    if (_phRegionMap.containsKey(key)) return _phRegionMap[key];
    return state;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white60,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Current location card ────────────────────────────────────────────────────
class _CurrentLocationCard extends StatelessWidget {
  final String cityName;
  final String country;
  final String? stateName;
  final double lat;
  final double lon;
  final OpenMeteoModel? weather;
  final VoidCallback onTap;

  const _CurrentLocationCard({
    required this.cityName,
    required this.country,
    this.stateName,
    required this.lat,
    required this.lon,
    required this.weather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather?.current;
    final code = current?.weatherCode ?? 0;
    final isDay = (current?.isDay ?? 1) == 1;
    final gradient = WeatherUtils.getWeatherGradient(code, isDay: isDay);
    final now = DateTime.now();
    final tz = weather?.timezone ?? '';
    final locationDetail = country.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primaryAccent.withAlpha(128),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // City icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    locationDetail,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      color: AppColors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${tz.isNotEmpty ? '· $tz' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          color: AppColors.white60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withAlpha(51),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primaryAccent.withAlpha(128),
                      ),
                    ),
                    child: const Text(
                      '• USING GPS',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (current != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.tempGradient.createShader(b),
                    child: Text(
                      '${current.temperature2m.round()}°',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    WeatherUtils.getWeatherDescription(code),
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      color: AppColors.white60,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    WeatherUtils.getWeatherIconAsset(code, isDay: isDay),
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
            ] else
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white40,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved location card ──────────────────────────────────────────────────────
class _SavedLocationCard extends StatelessWidget {
  final SavedLocation location;
  final OpenMeteoModel? weather;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSetHome;

  const _SavedLocationCard({
    required this.location,
    required this.weather,
    required this.onTap,
    required this.onDelete,
    required this.onSetHome,
  });

  // City landmark icons by country
  static IconData _cityIcon(String country) {
    switch (country) {
      case 'Japan':
        return Icons.temple_buddhist_rounded;
      case 'United Kingdom':
        return Icons.account_balance_rounded;
      case 'United States':
        return Icons.local_fire_department_rounded;
      case 'France':
        return Icons.museum_rounded;
      case 'Australia':
        return Icons.beach_access_rounded;
      case 'Philippines':
        return Icons.apartment_rounded;
      case 'Singapore':
        return Icons.business_rounded;
      case 'China':
        return Icons.villa_rounded;
      default:
        return Icons.location_city_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = weather?.current;
    final code = current?.weatherCode ?? 0;
    final isDay = (current?.isDay ?? 1) == 1;
    final gradient = WeatherUtils.getWeatherGradient(code, isDay: isDay);
    final cityLabel =
        LocationLabelFormatter.cityLine(location.name, location.state);
    final countryLabel = location.country.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: location.isHome
                ? AppColors.tempYellow.withAlpha(128)
                : AppColors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _cityIcon(location.country),
                color: Colors.white70,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cityLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      if (location.isHome) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tempYellow.withAlpha(51),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.tempYellow.withAlpha(128),
                            ),
                          ),
                          child: const Text(
                            'HOME',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tempYellow,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    countryLabel,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      color: AppColors.white60,
                    ),
                  ),
                  if (current != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      WeatherUtils.getWeatherDescription(code),
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        color: AppColors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (current != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.tempGradient.createShader(b),
                    child: Text(
                      '${current.temperature2m.round()}°',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    WeatherUtils.getWeatherIconAsset(code, isDay: isDay),
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ] else
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white40,
                ),
              ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.white60,
                size: 20,
              ),
              color: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                if (!location.isHome)
                  const PopupMenuItem(
                    value: 'home',
                    child: Row(
                      children: [
                        Icon(
                          Icons.home_rounded,
                          color: AppColors.tempYellow,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Set as Home',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.alertRed,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Remove',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          color: AppColors.alertRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'home') onSetHome();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent location card ─────────────────────────────────────────────────────
class _RecentLocationCard extends StatelessWidget {
  final GeocodingResult result;
  final OpenMeteoModel? weather;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  const _RecentLocationCard({
    required this.result,
    required this.weather,
    required this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather?.current;
    final code = current?.weatherCode ?? 0;
    final isDay = (current?.isDay ?? 1) == 1;
    final cityLabel = LocationLabelFormatter.cityLine(result.name, result.state,
        admin2: result.admin2);
    final countryLabel = result.country.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: AppColors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityLabel,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    countryLabel,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      color: AppColors.white60,
                    ),
                  ),
                ],
              ),
            ),
            if (current != null) ...[
              Text(
                WeatherUtils.getWeatherIconAsset(code, isDay: isDay),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                '${current.temperature2m.round()}°',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tempYellow,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (onSave != null)
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryAccent.withAlpha(102),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Search result card ───────────────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final GeocodingResult result;
  final bool alreadySaved;
  final VoidCallback onSetCurrent;
  final VoidCallback? onSave;

  const _SearchResultCard({
    required this.result,
    required this.alreadySaved,
    required this.onSetCurrent,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cityLabel = LocationLabelFormatter.cityLine(result.name, result.state,
        admin2: result.admin2);
    final countryLabel = result.country.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryBright,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityLabel,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      countryLabel,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        color: AppColors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Set as current location button
              Expanded(
                child: GestureDetector(
                  onTap: onSetCurrent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryAccent.withAlpha(102),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryBright,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Set as Current',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              Expanded(
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: alreadySaved
                          ? AppColors.white10
                          : AppColors.tempYellow.withAlpha(31),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: alreadySaved
                            ? AppColors.white20
                            : AppColors.tempYellow.withAlpha(102),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          alreadySaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_add_rounded,
                          color: alreadySaved
                              ? AppColors.white40
                              : AppColors.tempYellow,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alreadySaved ? 'Saved' : 'Save',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: alreadySaved
                                ? AppColors.white40
                                : AppColors.tempYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
