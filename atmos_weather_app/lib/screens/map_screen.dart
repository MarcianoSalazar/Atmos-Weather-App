import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAP SCREEN — Full featured:
//   ✅ OpenStreetMap base tiles (free, no key)
//   ✅ OpenWeatherMap cloud overlay (free, your API key)
//   ✅ OpenWeatherMap wind overlay (free, your API key)
//   ✅ Nominatim search autocomplete (free, no key — like Google Maps)
//   ✅ GPS auto-detect location
//   ✅ Zoom in/out buttons
//   ✅ Double-tap to select location and fetch its weather
//   ✅ Weather condition markers per tap
//   ✅ Country/city labels via OSM
// ─────────────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final MapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _showResults = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce; // debounce timer so we don't search every keystroke

  // ── Overlay toggles ────────────────────────────────────────────────────────
  bool _showClouds = true;
  bool _showWind = false;
  bool _showRain = false;

  // ── Tapped location weather ────────────────────────────────────────────────
  LatLng? _tappedPoint;
  Map<String, dynamic>? _tappedWeather; // weather at the tapped point
  bool _loadingTappedWeather = false;

  String get _owmKey => WeatherService.apiKey;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Nominatim Search (FREE — no API key needed) ──────────────────────────
  // Nominatim is the official search API of OpenStreetMap.
  // It returns city names, barangays, municipalities, roads — very specific,
  // similar to Google Maps search.
  Future<void> _searchNominatim(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // We add countrycodes=ph to bias Philippines results first,
      // but it still returns worldwide results.
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=10'
        '&countrycodes=ph', // bias PH first — remove if you want worldwide
      );

      final response = await http.get(url, headers: {
        // Nominatim requires a User-Agent header — use your app name
        'User-Agent': 'ATMOS-WeatherApp/1.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
          _showResults = true;
        });
      }
    } catch (_) {
      // Silently fail — user can still use the map
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // ─── Fetch weather at any tapped point ────────────────────────────────────
  Future<void> _fetchWeatherAtPoint(LatLng point) async {
    setState(() {
      _tappedPoint = point;
      _loadingTappedWeather = true;
      _tappedWeather = null;
    });

    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather'
          '?lat=${point.latitude}&lon=${point.longitude}'
          '&appid=$_owmKey&units=metric';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() => _tappedWeather = jsonDecode(response.body));
      }
    } catch (_) {
      // Show nothing if fetch fails
    } finally {
      setState(() => _loadingTappedWeather = false);
    }
  }

  // ─── Build OWM tile overlay URL ───────────────────────────────────────────
  // OpenWeatherMap provides free map tile overlays for:
  //   clouds_new, wind_new, precipitation_new, pressure_new, temp_new
  String _owmOverlayUrl(String layer) {
    return 'https://tile.openweathermap.org/map/$layer/{z}/{x}/{y}.png?appid=$_owmKey';
  }

  // ─── Helper: extract display name from Nominatim result ───────────────────
  String _getDisplayName(Map<String, dynamic> result) {
    final addr = result['address'] as Map<String, dynamic>?;
    if (addr == null) return result['display_name'] ?? '';

    // Build a clean label: "City, Province, Country"
    final parts = <String>[];
    final city = addr['city'] ??
        addr['town'] ??
        addr['village'] ??
        addr['municipality'] ??
        addr['suburb'] ??
        '';
    final province = addr['province'] ?? addr['state'] ?? addr['region'] ?? '';
    final country = addr['country'] ?? '';

    if (city.isNotEmpty) parts.add(city);
    if (province.isNotEmpty) parts.add(province);
    if (country.isNotEmpty) parts.add(country);

    return parts.isNotEmpty ? parts.join(', ') : result['display_name'] ?? '';
  }

  String _getSubtitle(Map<String, dynamic> result) {
    final addr = result['address'] as Map<String, dynamic>?;
    if (addr == null) return '';
    final road = addr['road'] ?? addr['street'] ?? '';
    final country = addr['country'] ?? '';
    if (road.isNotEmpty && country.isNotEmpty) return '$road, $country';
    return country;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final lat = provider.currentLat ?? 12.8797; // center of Philippines
        final lon = provider.currentLon ?? 121.7740;

        return GestureDetector(
          // Dismiss search when tapping outside
          onTap: () {
            if (_showResults) {
              setState(() => _showResults = false);
              _searchFocus.unfocus();
            }
          },
          child: Stack(
            children: [
              // ── MAIN MAP ─────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(lat, lon),
                  initialZoom: 6.5,
                  minZoom: 3.0,
                  maxZoom: 18.0,

                  // ── Single tap: fetch weather at tapped point ─────────────
                  onTap: (tapPos, point) {
                    if (_showResults) {
                      setState(() => _showResults = false);
                      _searchFocus.unfocus();
                      return;
                    }
                    _fetchWeatherAtPoint(point);
                  },

                  // ── Long-press: zoom in on that point ─────────────────────
                  onLongPress: (tapPos, point) {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(point, currentZoom + 1.5);
                    _fetchWeatherAtPoint(point);
                  },
                ),
                children: [
                  // ── Layer 1: OpenStreetMap base (free, no key) ─────────────
                  // OSM provides the street map with country/city labels
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.atmos.weather',
                    maxZoom: 18,
                  ),

                  // ── Layer 2: Cloud overlay (OWM — your API key) ────────────
                  if (_showClouds)
                    TileLayer(
                      urlTemplate: _owmOverlayUrl('clouds_new'),
                      userAgentPackageName: 'com.atmos.weather',
                    ),

                  // ── Layer 3: Wind overlay (OWM — your API key) ─────────────
                  if (_showWind)
                    TileLayer(
                      urlTemplate: _owmOverlayUrl('wind_new'),
                      userAgentPackageName: 'com.atmos.weather',
                    ),

                  // ── Layer 4: Rain/precipitation overlay ───────────────────
                  if (_showRain)
                    TileLayer(
                      urlTemplate: _owmOverlayUrl('precipitation_new'),
                      userAgentPackageName: 'com.atmos.weather',
                    ),

                  // ── Layer 5: Markers ───────────────────────────────────────
                  MarkerLayer(
                    markers: [
                      // GPS / current location marker
                      Marker(
                        point: LatLng(lat, lon),
                        width: 50,
                        height: 50,
                        child: _GpsMarker(),
                      ),

                      // Tapped point weather marker
                      if (_tappedPoint != null)
                        Marker(
                          point: _tappedPoint!,
                          width: 160,
                          height: 70,
                          alignment: Alignment.bottomCenter,
                          child: _WeatherMarker(
                            isLoading: _loadingTappedWeather,
                            weatherData: _tappedWeather,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // ── SEARCH BAR + RESULTS ──────────────────────────────────────
              Column(
                children: [
                  // Search bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      style: const TextStyle(
                          color: AtmosTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search city, barangay, or place...',
                        hintStyle: const TextStyle(
                            color: AtmosTheme.textLight, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AtmosTheme.primaryBlue, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AtmosTheme.textLight, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _showResults = false;
                                  });
                                  _searchFocus.unfocus();
                                },
                              )
                            : _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                      ),
                      onChanged: (v) {
                        // Debounce: wait 400ms after user stops typing
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () => _searchNominatim(v),
                        );
                        setState(() {});
                      },
                    ),
                  ),

                  // ── Autocomplete results list ─────────────────────────────
                  if (_showResults && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.52,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AtmosTheme.divider,
                          ),
                          itemBuilder: (context, i) {
                            final r = _searchResults[i];
                            final name = _getDisplayName(r);
                            final subtitle = _getSubtitle(r);
                            final type = r['type'] ?? r['class'] ?? '';

                            return _SearchResultTile(
                              name: name,
                              subtitle: subtitle,
                              placeType: type,
                              onTap: () {
                                // Move map to this location
                                final rLat =
                                    double.tryParse(r['lat'] ?? '0') ?? 0;
                                final rLon =
                                    double.tryParse(r['lon'] ?? '0') ?? 0;
                                final point = LatLng(rLat, rLon);

                                _mapController.move(point, 12.0);
                                _fetchWeatherAtPoint(point);

                                // Close results
                                _searchCtrl.clear();
                                setState(() {
                                  _showResults = false;
                                  _searchResults = [];
                                });
                                _searchFocus.unfocus();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),

              // ── OVERLAY TOGGLE BUTTONS (top-right) ───────────────────────
              if (!_showResults)
                Positioned(
                  top: 64,
                  right: 12,
                  child: Column(
                    children: [
                      // GPS — go back to current location
                      _MapIconBtn(
                        icon: Icons.my_location_rounded,
                        tooltip: 'My Location',
                        onTap: () =>
                            _mapController.move(LatLng(lat, lon), 10.0),
                      ),
                      const SizedBox(height: 6),
                      // Zoom in
                      _MapIconBtn(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Zoom out
                      _MapIconBtn(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── WEATHER LAYER TOGGLE PANEL (bottom-left) ─────────────────
              if (!_showResults)
                Positioned(
                  bottom: _tappedWeather != null ? 148 : 16,
                  left: 12,
                  child: _LayerPanel(
                    showClouds: _showClouds,
                    showWind: _showWind,
                    showRain: _showRain,
                    onToggleClouds: () =>
                        setState(() => _showClouds = !_showClouds),
                    onToggleWind: () => setState(() => _showWind = !_showWind),
                    onToggleRain: () => setState(() => _showRain = !_showRain),
                  ),
                ),

              // ── TAPPED LOCATION BOTTOM CARD ───────────────────────────────
              if (!_showResults &&
                  (_tappedWeather != null || _loadingTappedWeather))
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: _TappedWeatherCard(
                    isLoading: _loadingTappedWeather,
                    data: _tappedWeather,
                    onClose: () => setState(() {
                      _tappedWeather = null;
                      _tappedPoint = null;
                    }),
                    onViewHome: () async {
                      if (_tappedPoint != null) {
                        await provider.loadWeatherByCoords(
                          _tappedPoint!.latitude,
                          _tappedPoint!.longitude,
                        );
                      }
                      provider.setNavIndex(0);
                    },
                  ),
                ),

              // ── TAP HINT (shown when no tap yet) ──────────────────────────
              if (!_showResults &&
                  _tappedWeather == null &&
                  !_loadingTappedWeather)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '📍 Tap any place • Long-press to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GPS MARKER — pulsing blue dot for user's location
// ─────────────────────────────────────────────────────────────────────────────
class _GpsMarker extends StatefulWidget {
  @override
  State<_GpsMarker> createState() => _GpsMarkerState();
}

class _GpsMarkerState extends State<_GpsMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer ring
          Container(
            width: 46 * _anim.value,
            height: 46 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AtmosTheme.primaryBlue
                  .withOpacity(0.25 * (1 - _anim.value + 0.3)),
            ),
          ),
          // Inner solid dot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AtmosTheme.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AtmosTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEATHER MARKER — shown at tapped/double-tapped location
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherMarker extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? weatherData;

  const _WeatherMarker({required this.isLoading, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AtmosTheme.deepBlue.withOpacity(0.92),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : weatherData == null
                  ? const Text('No data',
                      style: TextStyle(color: Colors.white70, fontSize: 11))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          WeatherUtils.getWeatherEmoji(
                            weatherData!['weather']?[0]?['icon'] ?? '01d',
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(weatherData!['main']?['temp'] ?? 0).round()}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              weatherData!['name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
        // Pointer arrow
        CustomPaint(
          size: const Size(12, 7),
          painter:
              _TrianglePainter(color: AtmosTheme.deepBlue.withOpacity(0.92)),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH RESULT TILE — one row in the autocomplete list
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String placeType;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.name,
    required this.subtitle,
    required this.placeType,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
        return Icons.location_city_rounded;
      case 'village':
      case 'suburb':
      case 'neighbourhood':
        return Icons.holiday_village_rounded;
      case 'administrative':
      case 'province':
        return Icons.map_rounded;
      case 'road':
      case 'street':
        return Icons.add_road_rounded;
      case 'country':
        return Icons.flag_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Icon based on place type
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AtmosTheme.lightBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconForType(placeType),
                color: AtmosTheme.primaryBlue,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AtmosTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AtmosTheme.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AtmosTheme.textLight, size: 11),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYER PANEL — toggles for cloud / wind / rain overlays
// ─────────────────────────────────────────────────────────────────────────────
class _LayerPanel extends StatelessWidget {
  final bool showClouds;
  final bool showWind;
  final bool showRain;
  final VoidCallback onToggleClouds;
  final VoidCallback onToggleWind;
  final VoidCallback onToggleRain;

  const _LayerPanel({
    required this.showClouds,
    required this.showWind,
    required this.showRain,
    required this.onToggleClouds,
    required this.onToggleWind,
    required this.onToggleRain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'LAYERS',
            style: TextStyle(
              color: AtmosTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _LayerToggle(
            icon: '☁️',
            label: 'Clouds',
            active: showClouds,
            onTap: onToggleClouds,
          ),
          const SizedBox(height: 4),
          _LayerToggle(
            icon: '💨',
            label: 'Wind',
            active: showWind,
            onTap: onToggleWind,
          ),
          const SizedBox(height: 4),
          _LayerToggle(
            icon: '🌧️',
            label: 'Rain',
            active: showRain,
            onTap: onToggleRain,
          ),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AtmosTheme.primaryBlue.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? AtmosTheme.primaryBlue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? AtmosTheme.primaryBlue : AtmosTheme.textSecondary,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAPPED WEATHER CARD — bottom sheet showing weather at tapped location
// ─────────────────────────────────────────────────────────────────────────────
class _TappedWeatherCard extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final VoidCallback onClose;
  final VoidCallback onViewHome;

  const _TappedWeatherCard({
    required this.isLoading,
    required this.data,
    required this.onClose,
    required this.onViewHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : data == null
              ? const Text('Could not load weather for this location.')
              : Row(
                  children: [
                    // Weather emoji icon
                    Text(
                      WeatherUtils.getWeatherEmoji(
                        data!['weather']?[0]?['icon'] ?? '01d',
                      ),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 12),
                    // Weather info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data!['name'] ?? 'Unknown Location',
                            style: const TextStyle(
                              color: AtmosTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${data!['sys']?['country'] ?? ''}',
                            style: const TextStyle(
                              color: AtmosTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _WeatherChip(
                                icon: Icons.thermostat_rounded,
                                label:
                                    '${(data!['main']?['temp'] ?? 0).round()}°C',
                              ),
                              const SizedBox(width: 6),
                              _WeatherChip(
                                icon: Icons.water_drop_rounded,
                                label: '${data!['main']?['humidity'] ?? 0}%',
                              ),
                              const SizedBox(width: 6),
                              _WeatherChip(
                                icon: Icons.air_rounded,
                                label:
                                    '${(data!['wind']?['speed'] ?? 0).toStringAsFixed(1)} km/h',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AtmosTheme.divider,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: AtmosTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onViewHome,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AtmosTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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

class _WeatherChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AtmosTheme.lightBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AtmosTheme.primaryBlue),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: AtmosTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP ICON BUTTON — zoom/location control buttons on the right side
// ─────────────────────────────────────────────────────────────────────────────
class _MapIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _MapIconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AtmosTheme.textPrimary, size: 20),
        ),
      ),
    );
  }
}
