import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

enum WeatherStatus { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherStatus _status = WeatherStatus.initial;
  WeatherData? _currentWeather;
  List<ForecastDay> _forecast = [];
  List<HourlyForecast> _hourlyForecast = [];
  List<WeatherAlert> _alerts = [];
  String _errorMessage = '';
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  double? _currentLat;
  double? _currentLon;
  int _selectedNavIndex = 0;

  // Getters
  WeatherStatus get status => _status;
  WeatherData? get currentWeather => _currentWeather;
  List<ForecastDay> get forecast => _forecast;
  List<HourlyForecast> get hourlyForecast => _hourlyForecast;
  List<WeatherAlert> get alerts => _alerts;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoaded => _status == WeatherStatus.loaded;

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  Future<void> loadWeatherByLocation() async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentLat = position.latitude;
        _currentLon = position.longitude;
        await _fetchAllWeatherData(position.latitude, position.longitude);
      }
    } catch (e) {
      // Fallback to Manila
      _currentLat = 14.5995;
      _currentLon = 120.9842;
      await _fetchAllWeatherData(14.5995, 120.9842);
    }
  }

  Future<void> loadWeatherByCity(String cityName) async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final weather = await _weatherService.getCurrentWeatherByCity(cityName);
      _currentLat = weather.lat;
      _currentLon = weather.lon;
      await _fetchAllWeatherData(weather.lat, weather.lon,
          preloadedWeather: weather);
    } catch (e) {
      _status = WeatherStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadWeatherByCoords(double lat, double lon) async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentLat = lat;
      _currentLon = lon;
      await _fetchAllWeatherData(lat, lon);
    } catch (e) {
      _status = WeatherStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _fetchAllWeatherData(double lat, double lon,
      {WeatherData? preloadedWeather}) async {
    try {
      final results = await Future.wait([
        preloadedWeather != null
            ? Future.value(preloadedWeather)
            : _weatherService.getCurrentWeatherByCoords(lat, lon),
        _weatherService.getForecastByCoords(lat, lon),
        _weatherService.getHourlyForecast(lat, lon),
        _weatherService.getUvIndex(lat, lon),

        // 🔥 NEW: fetch alerts
        _weatherService.getWeatherAlerts(lat, lon),
      ]);

      final uvIndex = results[3] as int;

      _currentWeather =
          (results[0] as WeatherData).copyWith(uvIndex: uvIndex);
      _forecast = results[1] as List<ForecastDay>;
      _hourlyForecast = results[2] as List<HourlyForecast>;

      // ✅ REAL ALERTS
      _alerts = results[4] as List<WeatherAlert>;

      _status = WeatherStatus.loaded;
    } catch (e) {
      _status = WeatherStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentLat != null && _currentLon != null) {
      await _fetchAllWeatherData(_currentLat!, _currentLon!);
    } else {
      await loadWeatherByLocation();
    }
  }

  Future<void> searchCities(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      _searchResults = await _weatherService.searchCities(query);
    } catch (_) {
      _searchResults = [];
    }
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  // Reminder messages (UNCHANGED)
  List<Map<String, dynamic>> get contextReminders {
    if (_currentWeather == null) return [];
    final reminders = <Map<String, dynamic>>[];
    final temp = _currentWeather!.temperature;
    final cond = _currentWeather!.mainCondition.toLowerCase();

    if (temp >= 35) {
      reminders.add({
        'icon': '🌡️',
        'title': 'Extreme heat today',
        'body': 'Avoid outdoor activities during peak hours. Stay hydrated.',
      });
    } else if (temp >= 30) {
      reminders.add({
        'icon': '☀️',
        'title': 'Hot weather today',
        'body':
            'Dress in light clothing to stay comfortable throughout the day.',
      });
    }
    if (cond.contains('rain') || cond.contains('drizzle')) {
      reminders.add({
        'icon': '🌧️',
        'title': 'Rain is expected today',
        'body': 'Remember to bring an umbrella to stay dry on your way home.',
      });
    }
    if (cond.contains('thunderstorm')) {
      reminders.add({
        'icon': '⛈️',
        'title': 'Thunderstorm warning',
        'body':
            'Stay indoors if possible. Avoid open areas and tall structures.',
      });
    }
    reminders.add({
      'icon': '💧',
      'title': 'Stay hydrated',
      'body':
          'Carry a water bottle to keep yourself hydrated throughout the day.',
    });
    if (cond.contains('clear') || cond.contains('sun')) {
      reminders.add({
        'icon': '🧴',
        'title': 'Stay protected under the sun',
        'body': 'Apply sunscreen. Have fun outside without harming your skin.',
      });
    }
    return reminders;
  }

  ForecastDay? get hottestDay {
    if (_forecast.isEmpty) return null;
    return _forecast.reduce((a, b) => a.tempMax > b.tempMax ? a : b);
  }

  ForecastDay? get coolestDay {
    if (_forecast.isEmpty) return null;
    return _forecast.reduce((a, b) => a.tempMin < b.tempMin ? a : b);
  }
}