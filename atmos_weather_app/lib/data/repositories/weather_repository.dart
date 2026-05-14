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

  // Fetch current + hourly + daily forecast from Open-Meteo (FREE, no key required)
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

      // Cache the result
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

  // Fetch air quality from Open-Meteo Air Quality API (FREE)
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

  // Search locations using Open-Meteo Geocoding API (FREE)
  Future<List<GeocodingResult>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    if (kIsWeb) {
      final webResults = await _searchGeoapify(trimmed);
      if (webResults.isNotEmpty) return webResults;

      final fallback = trimmed.split(',').first.trim();
      if (fallback.isNotEmpty && fallback != trimmed) {
        return _searchGeoapify(fallback);
      }

      return [];
    }

    final results = await _searchOpenMeteo(trimmed);
    if (results.isNotEmpty) return results;

    // If the user typed "City, Country", retry using the city only.
    final fallback = trimmed.split(',').first.trim();
    if (fallback.isNotEmpty && fallback != trimmed) {
      return _searchOpenMeteo(fallback);
    }

    return [];
  }

  Future<List<GeocodingResult>> _searchOpenMeteo(String query) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': query,
          'count': 10,
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
          .map(
            (e) => GeocodingResult(
              name: e['name'] as String,
              lat: (e['latitude'] as num).toDouble(),
              lon: (e['longitude'] as num).toDouble(),
              country: e['country'] as String? ?? '',
              state: e['admin1'] as String?,
            ),
          )
          .toList();

      return results;
    } on DioException catch (e) {
      _logger.e('Geocoding search error: ${e.message}');
      return [];
    } on FormatException catch (e) {
      _logger.e('Geocoding parse error: ${e.message}');
      return [];
    }
  }

  Future<List<GeocodingResult>> _searchGeoapify(String query) async {
    if (AppConstants.geoapifyApiKey == 'YOUR_GEOAPIFY_API_KEY') {
      return [];
    }
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://api.geoapify.com/v1/geocode/search',
        queryParameters: {
          'text': query,
          'format': 'json',
          'limit': 10,
          'apiKey': AppConstants.geoapifyApiKey,
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

      final results = (data['results'] as List<dynamic>? ?? []).map((e) {
        final name = (e['city'] as String?) ??
            (e['town'] as String?) ??
            (e['village'] as String?) ??
            (e['name'] as String?) ??
            (e['formatted'] as String?) ??
            query;
        final state = (e['state'] as String?) ??
            (e['county'] as String?) ??
            (e['region'] as String?);
        final country = e['country'] as String? ?? '';
        return GeocodingResult(
          name: name,
          lat: (e['lat'] as num).toDouble(),
          lon: (e['lon'] as num).toDouble(),
          country: country,
          state: state,
        );
      }).toList();

      return results;
    } on DioException catch (e) {
      _logger.e('Geoapify search error: ${e.message}');
      return [];
    } on FormatException catch (e) {
      _logger.e('Geoapify parse error: ${e.message}');
      return [];
    }
  }

  // Reverse geocode using Geoapify (web-friendly)
  Future<GeocodingResult?> reverseGeocodeGeoapify({
    required double lat,
    required double lon,
  }) async {
    if (AppConstants.geoapifyApiKey == 'YOUR_GEOAPIFY_API_KEY') {
      return null;
    }
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://api.geoapify.com/v1/geocode/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'apiKey': AppConstants.geoapifyApiKey,
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

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final name = (first['city'] as String?) ??
          (first['town'] as String?) ??
          (first['village'] as String?) ??
          (first['suburb'] as String?) ??
          (first['hamlet'] as String?) ??
          (first['name'] as String?) ??
          (first['formatted'] as String?) ??
          '';
      final state = (first['state'] as String?) ??
          (first['county'] as String?) ??
          (first['region'] as String?) ??
          (first['state_district'] as String?);

      return GeocodingResult(
        name: name,
        lat: (first['lat'] as num?)?.toDouble() ?? lat,
        lon: (first['lon'] as num?)?.toDouble() ?? lon,
        country: first['country'] as String? ?? '',
        state: state,
      );
    } on DioException catch (e) {
      _logger.e('Geoapify reverse geocode error: ${e.message}');
      return null;
    } on FormatException catch (e) {
      _logger.e('Geoapify reverse geocode parse error: ${e.message}');
      return null;
    }
  }

  // Reverse geocode using OpenWeatherMap (more specific place names)
  Future<GeocodingResult?> reverseGeocodeOwm({
    required double lat,
    required double lon,
  }) async {
    if (kIsWeb) {
      return null; // OWM reverse geocode is blocked by CORS on web builds.
    }
    if (AppConstants.openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      return null;
    }
    try {
      final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
        '${AppConstants.owmGeoUrl}/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'limit': 1,
          'appid': AppConstants.openWeatherApiKey,
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      return GeocodingResult(
        name: first['name'] as String? ?? '',
        lat: (first['lat'] as num?)?.toDouble() ?? lat,
        lon: (first['lon'] as num?)?.toDouble() ?? lon,
        country: first['country'] as String? ?? '',
        state: first['state'] as String?,
      );
    } on DioException catch (e) {
      _logger.e('OWM reverse geocode error: ${e.message}');
      return null;
    }
  }

  // Get weather for multiple saved locations
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

  // Fetch OpenWeatherMap data (with API key)
  Future<Map<String, dynamic>?> fetchOpenWeatherMap({
    required double lat,
    required double lon,
  }) async {
    if (AppConstants.openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      return null; // Skip if no key configured
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

  // Saved Locations CRUD
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

  // Recent locations
  List<GeocodingResult> getRecentLocations({int max = 3}) {
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
    int max = 3,
  }) async {
    final current = getRecentLocations(max: max);
    current.removeWhere(
      (r) => r.lat == result.lat && r.lon == result.lon,
    );
    current.insert(0, result);
    final trimmed = current.length > max ? current.sublist(0, max) : current;
    await _prefs.setString(
      AppConstants.recentLocationsKey,
      jsonEncode(
        trimmed
            .map(
              (r) => {
                'name': r.name,
                'lat': r.lat,
                'lon': r.lon,
                'country': r.country,
                'state': r.state,
              },
            )
            .toList(),
      ),
    );
  }

  // Alerts
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

  // Settings
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

  // Cache helpers
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
