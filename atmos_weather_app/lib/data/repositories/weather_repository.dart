// lib/data/repositories/weather_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../../core/constants/app_constants.dart';

class WeatherRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  final ValueNotifier<int> unreadAlerts = ValueNotifier<int>(0);

  WeatherRepository({required Dio dio, required SharedPreferences prefs})
      : _dio = dio,
        _prefs = prefs {
    _refreshUnreadAlerts();
  }

  // ─── Open-Meteo forecast ──────────────────────────────────────────────────

  Future<OpenMeteoModel> fetchOpenMeteoForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        AppConstants.openMeteoUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': [
            'temperature_2m',
            'relative_humidity_2m',
            'apparent_temperature',
            'is_day',
            'precipitation',
            'weather_code',
            'cloud_cover',
            'wind_speed_10m',
            'wind_direction_10m',
            'surface_pressure',
          ].join(','),
          'hourly': [
            'temperature_2m',
            'relative_humidity_2m',
            'precipitation_probability',
            'weather_code',
            'wind_speed_10m',
            'uv_index',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'sunrise',
            'sunset',
            'uv_index_max',
            'precipitation_sum',
            'wind_speed_10m_max',
          ].join(','),
          'timezone': 'auto',
          'forecast_days': 7,
          'wind_speed_unit': 'kmh',
        },
      );

      final model =
          OpenMeteoModel.fromJson(response.data as Map<String, dynamic>);

      await _prefs.setString(
        AppConstants.currentWeatherCache,
        jsonEncode(response.data),
      );
      await _prefs.setString(
        '${AppConstants.currentWeatherCache}_time',
        DateTime.now().toIso8601String(),
      );

      return model;
    } on DioException catch (e) {
      _logger.e('Weather fetch error: ${e.message}');
      return _getCachedOpenMeteo() ??
          (throw Exception('Failed to fetch weather data'));
    }
  }

  // ─── Air quality ──────────────────────────────────────────────────────────

  Future<AirQualityModel?> fetchAirQuality({
    required double lat,
    required double lon,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        AppConstants.openMeteoAirQualityUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': [
            'european_aqi',
            'pm10',
            'pm2_5',
            'carbon_monoxide',
            'nitrogen_dioxide',
            'sulphur_dioxide',
            'ozone',
            'dust',
            'uv_index',
          ].join(','),
          'timezone': 'auto',
        },
      );

      return AirQualityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Air quality fetch error: ${e.message}');
      return null;
    }
  }

  // ─── Forward geocoding (search) — OWM only ────────────────────────────────
  //
  // OWM Geocoding API returns:
  //   name      → city / town / municipality
  //   local_names → localised names (we use 'en' when present)
  //   country   → ISO-2 code  (we expand to full name)
  //   state     → admin1: province / state / region
  //
  // We store:
  //   GeocodingResult.name    = city/town/municipality
  //   GeocodingResult.admin2  = province  (= OWM `state` field, which is
  //                             actually the province for PH, not a region)
  //   GeocodingResult.country = full country name
  //   GeocodingResult.state   = same as admin2 (kept for legacy callers)

  Future<List<GeocodingResult>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = <GeocodingResult>[];
    final seen = <String>{};

    Future<void> addResults(Future<List<GeocodingResult>> future) async {
      final batch = await future;
      for (final result in batch) {
        final key =
            '${result.lat.toStringAsFixed(2)}_${result.lon.toStringAsFixed(2)}';
        if (seen.add(key)) {
          results.add(result);
        }
      }
    }

    Future<void> searchVariant(String value) async {
      if (value.trim().isEmpty) return;
      if (AppConstants.openWeatherApiKey.isNotEmpty &&
          AppConstants.openWeatherApiKey != 'YOUR_OPENWEATHERMAP_API_KEY') {
        await addResults(_searchOwmGeocoding(value));
      }
      await addResults(_searchOpenMeteoGeocoding(value));
    }

    await searchVariant(trimmed);

    final shorter = _shortenLocationQuery(trimmed);
    if ((results.isEmpty || results.every(_isProvinceLikeResult)) &&
        shorter != null &&
        shorter != trimmed) {
      await searchVariant(shorter);
    }

    if (results.isEmpty && !trimmed.toLowerCase().contains('philippines')) {
      await searchVariant('$trimmed Philippines');
    }

    return results;
  }

  Future<List<GeocodingResult>> _searchOwmGeocoding(String query) async {
    try {
      final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
        '${AppConstants.owmGeoUrl}/direct',
        queryParameters: {
          'q': query,
          'limit': 10,
          'appid': AppConstants.openWeatherApiKey,
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) return [];

      final results = <GeocodingResult>[];
      for (final e in data) {
        final r = e as Map<String, dynamic>;

        // Prefer English local name if available
        final localNames = r['local_names'] as Map<String, dynamic>?;
        final name = (localNames?['en'] as String?) ??
            (r['name'] as String? ?? '').trim();
        if (name.isEmpty || _looksLikeRoad(name)) continue;

        final lat = (r['lat'] as num?)?.toDouble();
        final lon = (r['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        // OWM `state` = province for PH (e.g. "Laguna"), state for US, etc.
        final province = _normalizeAdminName((r['state'] as String?)?.trim());
        final countryIso = (r['country'] as String? ?? '').trim();
        final countryFull = _expandCountry(countryIso);

        results.add(GeocodingResult(
          name: name,
          lat: lat,
          lon: lon,
          country: countryFull,
          state: province, // region/state (internal)
          admin2: province, // province shown in UI
        ));
      }

      // Deduplicate by ~1 km grid
      final seen = <String>{};
      return results.where((r) {
        final key = '${r.lat.toStringAsFixed(2)}_${r.lon.toStringAsFixed(2)}';
        return seen.add(key);
      }).toList();
    } on DioException catch (e) {
      _logger.e('OWM geocoding search error: ${e.message}');
      return [];
    }
  }

  /// Open-Meteo free geocoding fallback (no API key needed).
  Future<List<GeocodingResult>> _searchOpenMeteoGeocoding(String query) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': query,
          'count': 20,
          'language': 'en',
          'format': 'json',
        },
      );

      final payload = response.data;
      Map<String, dynamic> data;
      if (payload is Map<String, dynamic>) {
        data = payload;
      } else if (payload is String) {
        data = jsonDecode(payload) as Map<String, dynamic>;
      } else {
        data = <String, dynamic>{};
      }

      final results = (data['results'] as List<dynamic>? ?? [])
          .map((e) {
            final name = (e['name'] as String? ?? '').trim();
            final province = _normalizeAdminName(
              (e['admin2'] as String?)?.trim() ??
                  (e['admin1'] as String?)?.trim(),
            );
            final countryRaw = e['country'] as String? ?? '';
            final countryFull = _expandCountry(countryRaw.length == 2
                ? countryRaw
                : (e['country_code'] as String? ?? countryRaw));
            return GeocodingResult(
              name: name,
              lat: (e['latitude'] as num).toDouble(),
              lon: (e['longitude'] as num).toDouble(),
              country: countryFull,
              state: _normalizeAdminName((e['admin1'] as String?)?.trim()),
              admin2: province,
            );
          })
          .where((r) => r.name.isNotEmpty)
          .toList();

      return results;
    } on DioException catch (e) {
      _logger.e('Open-Meteo geocoding fallback error: ${e.message}');
      return [];
    }
  }

  // ─── Reverse geocoding — OWM only ────────────────────────────────────────
  //
  // OWM /geo/1.0/reverse returns:
  //   name    → city/town/municipality  (curated, avoids road names)
  //   country → ISO-2 (we expand)
  //   state   → province/state (e.g. "Laguna" for PH, "California" for US)
  //
  // Display format: "Calauan, Laguna [Philippines]"
  //   cityName  = name
  //   admin2    = state  (province)
  //   country   = _expandCountry(country ISO-2)

  Future<GeocodingResult?> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    if (kIsWeb) return null; // CORS blocks OWM on web
    if (AppConstants.openWeatherApiKey.isEmpty ||
        AppConstants.openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      return null;
    }

    try {
      final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
        '${AppConstants.owmGeoUrl}/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'limit': 5,
          'appid': AppConstants.openWeatherApiKey,
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) return null;

      // Pick first non-road result
      Map<String, dynamic>? best;
      for (final e in data) {
        final r = e as Map<String, dynamic>;
        final n = (r['name'] as String? ?? '').trim();
        if (n.isNotEmpty && !_looksLikeRoad(n)) {
          best = r;
          break;
        }
      }
      if (best == null) return null;

      // Prefer English local name when available
      final localNames = best['local_names'] as Map<String, dynamic>?;
      final cityName = (localNames?['en'] as String?)?.trim() ??
          (best['name'] as String? ?? '').trim();

      if (cityName.isEmpty) return null;

      // OWM `state` = province for PH (e.g. "Laguna"), state for US, etc.
      final province = _normalizeAdminName((best['state'] as String?)?.trim());
      final countryIso = (best['country'] as String? ?? '').trim();
      final countryFull = _expandCountry(countryIso);

      return GeocodingResult(
        name: cityName,
        lat: lat,
        lon: lon,
        country: countryFull,
        state: province, // kept for legacy callers
        admin2: province, // province shown in UI: "Calauan, Laguna"
      );
    } on DioException catch (e) {
      _logger.e('OWM reverse geocode error: ${e.message}');
      return null;
    }
  }

  // ─── ISO-2 → full country name ────────────────────────────────────────────

  static const Map<String, String> _isoToCountry = {
    'PH': 'Philippines',
    'US': 'United States',
    'GB': 'United Kingdom',
    'AU': 'Australia',
    'CA': 'Canada',
    'JP': 'Japan',
    'KR': 'South Korea',
    'CN': 'China',
    'IN': 'India',
    'SG': 'Singapore',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
    'TH': 'Thailand',
    'VN': 'Vietnam',
    'DE': 'Germany',
    'FR': 'France',
    'IT': 'Italy',
    'ES': 'Spain',
    'BR': 'Brazil',
    'MX': 'Mexico',
    'ZA': 'South Africa',
    'AE': 'United Arab Emirates',
    'SA': 'Saudi Arabia',
    'NZ': 'New Zealand',
    'HK': 'Hong Kong',
    'TW': 'Taiwan',
    'NL': 'Netherlands',
    'SE': 'Sweden',
    'NO': 'Norway',
    'DK': 'Denmark',
    'FI': 'Finland',
    'PT': 'Portugal',
    'RU': 'Russia',
    'TR': 'Turkey',
    'PL': 'Poland',
    'UA': 'Ukraine',
    'NG': 'Nigeria',
    'EG': 'Egypt',
    'KE': 'Kenya',
    'GH': 'Ghana',
    'ET': 'Ethiopia',
    'PK': 'Pakistan',
    'BD': 'Bangladesh',
    'LK': 'Sri Lanka',
    'MM': 'Myanmar',
    'KH': 'Cambodia',
    'LA': 'Laos',
    'TL': 'Timor-Leste',
    'BN': 'Brunei',
    'MO': 'Macau',
    'AR': 'Argentina',
    'CL': 'Chile',
    'CO': 'Colombia',
    'PE': 'Peru',
    'VE': 'Venezuela',
    'EC': 'Ecuador',
  };

  static String _expandCountry(String raw) {
    final t = raw.trim();
    if (t.length != 2) return t;
    return _isoToCountry[t.toUpperCase()] ?? t;
  }

  static String? _normalizeAdminName(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return value;
    return value.replaceFirst(
        RegExp(r'^(province of|provincia de)\s+', caseSensitive: false), '');
  }

  static bool _looksLikeRoad(String s) {
    final lo = s.toLowerCase();
    const roadWords = [
      ' road',
      ' rd',
      ' street',
      ' st.',
      ' avenue',
      ' ave',
      ' highway',
      ' hwy',
      ' boulevard',
      ' blvd',
      ' drive',
      ' dr',
      ' lane',
      ' ln',
      ' expressway',
      ' freeway',
      ' bypass',
      ' national road',
      ' national highway',
      ' flyover',
      ' overpass',
    ];
    for (final w in roadWords) {
      if (lo.endsWith(w) || lo.contains('$w ') || lo.contains('$w,')) {
        return true;
      }
    }
    return false;
  }

  static bool _isProvinceLikeResult(GeocodingResult result) {
    final name = result.name.trim().toLowerCase();
    final admin2 = result.admin2?.trim().toLowerCase() ?? '';
    final state = result.state?.trim().toLowerCase() ?? '';
    return name.startsWith('province of ') ||
        (name.isNotEmpty && name == admin2) ||
        (name.isNotEmpty && name == state);
  }

  static String? _shortenLocationQuery(String query) {
    final cleaned = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;

    if (cleaned.contains(',')) {
      final parts = cleaned.split(',').map((p) => p.trim()).toList();
      if (parts.first.isNotEmpty) return parts.first;
    }

    final words = cleaned.split(' ');
    if (words.length <= 1) return null;
    return words.sublist(0, words.length - 1).join(' ').trim();
  }

  // ─── Multiple saved locations weather ─────────────────────────────────────

  Future<Map<String, OpenMeteoModel>> fetchMultipleLocations(
    List<SavedLocation> locations,
  ) async {
    final Map<String, OpenMeteoModel> results = {};
    for (final loc in locations) {
      try {
        final weather =
            await fetchOpenMeteoForecast(lat: loc.lat, lon: loc.lon);
        results[loc.id] = weather;
      } catch (e) {
        _logger.e('Failed to fetch weather for ${loc.name}: $e');
      }
    }
    return results;
  }

  // ─── OWM One-Call (optional) ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchOpenWeatherMap({
    required double lat,
    required double lon,
  }) async {
    if (AppConstants.openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      return null;
    }
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        '${AppConstants.owmOneCallUrl}/onecall',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': AppConstants.openWeatherApiKey,
          'units': 'metric',
          'exclude': 'minutely',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('OWM fetch error: ${e.message}');
      return null;
    }
  }

  // ─── Saved locations CRUD ─────────────────────────────────────────────────

  List<SavedLocation> getSavedLocations() {
    final stored = _prefs.getString(AppConstants.savedLocationsKey);
    if (stored == null) return [];
    try {
      final List<dynamic> parsed = jsonDecode(stored) as List<dynamic>;
      return parsed
          .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveLocation(SavedLocation location) async {
    final locations = getSavedLocations();
    final exists = locations.any((l) => l.id == location.id);
    if (!exists) {
      locations.add(location);
      await _prefs.setString(
        AppConstants.savedLocationsKey,
        jsonEncode(locations.map((l) => l.toJson()).toList()),
      );
    }
  }

  Future<void> removeLocation(String locationId) async {
    final locations = getSavedLocations();
    locations.removeWhere((l) => l.id == locationId);
    await _prefs.setString(
      AppConstants.savedLocationsKey,
      jsonEncode(locations.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> setHomeLocation(String locationId) async {
    final locations = getSavedLocations();
    for (var i = 0; i < locations.length; i++) {
      locations[i] =
          locations[i].copyWith(isHome: locations[i].id == locationId);
    }
    await _prefs.setString(
      AppConstants.savedLocationsKey,
      jsonEncode(locations.map((l) => l.toJson()).toList()),
    );
  }

  // ─── Recent locations ─────────────────────────────────────────────────────

  List<GeocodingResult> getRecentLocations({int max = 5}) {
    final stored = _prefs.getString(AppConstants.recentLocationsKey);
    if (stored == null) return [];
    try {
      final List<dynamic> parsed = jsonDecode(stored) as List<dynamic>;
      final results = parsed
          .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
          .toList();
      return results.length > max ? results.sublist(0, max) : results;
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentLocation(
    GeocodingResult result, {
    int max = 5,
  }) async {
    final current = getRecentLocations(max: max);
    current.removeWhere((r) =>
        (r.lat - result.lat).abs() < 0.01 && (r.lon - result.lon).abs() < 0.01);
    current.insert(0, result);
    final trimmed = current.length > max ? current.sublist(0, max) : current;
    await _prefs.setString(
      AppConstants.recentLocationsKey,
      jsonEncode(
        trimmed
            .map((r) => {
                  'name': r.name,
                  'lat': r.lat,
                  'lon': r.lon,
                  'country': r.country,
                  'state': r.state,
                  'admin2': r.admin2,
                })
            .toList(),
      ),
    );
  }

  /// Clears all recent location search history.
  Future<void> clearRecentLocations() async {
    await _prefs.remove(AppConstants.recentLocationsKey);
  }

  // ─── Alerts ───────────────────────────────────────────────────────────────

  List<WeatherAlert> getStoredAlerts() {
    final stored = _prefs.getString(AppConstants.alertsKey);
    if (stored == null) return [];
    try {
      final List<dynamic> parsed = jsonDecode(stored) as List<dynamic>;
      return parsed
          .map((e) => WeatherAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAlerts(List<WeatherAlert> alerts) async {
    await _prefs.setString(
      AppConstants.alertsKey,
      jsonEncode(alerts.map((a) => a.toJson()).toList()),
    );
    unreadAlerts.value = alerts.where((a) => !a.isRead).length;
  }

  Future<void> markAlertRead(String alertId) async {
    final alerts = getStoredAlerts();
    final idx = alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      alerts[idx] = alerts[idx].copyWith(isRead: true);
      await _prefs.setString(
        AppConstants.alertsKey,
        jsonEncode(alerts.map((a) => a.toJson()).toList()),
      );
      unreadAlerts.value = alerts.where((a) => !a.isRead).length;
    }
  }

  Future<void> clearAllAlerts() async {
    await _prefs.remove(AppConstants.alertsKey);
    unreadAlerts.value = 0;
  }

  void _refreshUnreadAlerts() {
    final alerts = getStoredAlerts();
    unreadAlerts.value = alerts.where((a) => !a.isRead).length;
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  AppSettings getSettings() {
    final stored = _prefs.getString(AppConstants.settingsKey);
    if (stored == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (e) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(
      AppConstants.settingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  // ─── Cache helpers ────────────────────────────────────────────────────────

  OpenMeteoModel? _getCachedOpenMeteo() {
    final stored = _prefs.getString(AppConstants.currentWeatherCache);
    if (stored == null) return null;
    try {
      return OpenMeteoModel.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  bool isCacheValid() {
    final timeStr =
        _prefs.getString('${AppConstants.currentWeatherCache}_time');
    if (timeStr == null) return false;
    final cachedTime = DateTime.tryParse(timeStr);
    if (cachedTime == null) return false;
    return DateTime.now().difference(cachedTime) <
        AppConstants.weatherCacheDuration;
  }
}
