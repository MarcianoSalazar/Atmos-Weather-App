import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // Replace with your OpenWeatherMap API key
  // Get free key at: https://openweathermap.org/api
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Get current weather by coordinates
  Future<WeatherData> getCurrentWeatherByCoords(
      double lat, double lon) async {
    final url =
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
    return _fetchCurrentWeather(url);
  }

  // Get current weather by city name
  Future<WeatherData> getCurrentWeatherByCity(String cityName) async {
    final url =
        '$_baseUrl/weather?q=${Uri.encodeComponent(cityName)}&appid=$_apiKey&units=metric';
    return _fetchCurrentWeather(url);
  }

  Future<WeatherData> _fetchCurrentWeather(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WeatherData.fromJson(json);
      } else if (response.statusCode == 404) {
        throw WeatherException('City not found. Please check the name.');
      } else if (response.statusCode == 401) {
        throw WeatherException('Invalid API key. Check your configuration.');
      } else {
        throw WeatherException('Weather service unavailable (${response.statusCode}).');
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Connection failed. Check your internet.');
    }
  }

  // Get 5-day forecast by coordinates
  Future<List<ForecastDay>> getForecastByCoords(
      double lat, double lon) async {
    final url =
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
    return _fetchForecast(url);
  }

  // Get 5-day forecast by city
  Future<List<ForecastDay>> getForecastByCity(String cityName) async {
    final url =
        '$_baseUrl/forecast?q=${Uri.encodeComponent(cityName)}&appid=$_apiKey&units=metric';
    return _fetchForecast(url);
  }

  Future<List<ForecastDay>> _fetchForecast(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return _parseForecast(json);
      } else {
        throw WeatherException('Forecast unavailable.');
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Connection failed. Check your internet.');
    }
  }

  List<ForecastDay> _parseForecast(Map<String, dynamic> json) {
    final List list = json['list'] ?? [];
    final Map<String, List<dynamic>> grouped = {};

    for (var item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final List<ForecastDay> days = [];
    final today =
        DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (final entry in grouped.entries) {
      if (entry.key == todayKey) continue;
      if (days.length >= 7) break;

      final items = entry.value;
      double maxTemp = -999;
      double minTemp = 999;
      double totalHumidity = 0;
      double totalWind = 0;
      double totalRain = 0;
      String icon = '01d';
      String desc = '';
      String main = '';

      // Use noon reading for icon/desc, or fallback to first
      dynamic noonItem = items.firstWhere(
        (i) {
          final dt = DateTime.fromMillisecondsSinceEpoch(i['dt'] * 1000);
          return dt.hour >= 11 && dt.hour <= 13;
        },
        orElse: () => items[items.length ~/ 2],
      );

      for (var item in items) {
        final temp = (item['main']?['temp'] ?? 0).toDouble();
        if (temp > maxTemp) maxTemp = temp;
        if (temp < minTemp) minTemp = temp;
        totalHumidity += (item['main']?['humidity'] ?? 0).toDouble();
        totalWind += (item['wind']?['speed'] ?? 0).toDouble();
        totalRain += ((item['pop'] ?? 0) as num).toDouble();
      }

      icon = noonItem['weather']?[0]?['icon'] ?? '01d';
      desc = noonItem['weather']?[0]?['description'] ?? '';
      main = noonItem['weather']?[0]?['main'] ?? '';

      final parts = entry.key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      days.add(ForecastDay(
        date: date,
        tempMax: maxTemp,
        tempMin: minTemp,
        description: desc,
        mainCondition: main,
        iconCode: icon,
        humidity: totalHumidity / items.length,
        windSpeed: totalWind / items.length,
        rainChance: (totalRain / items.length) * 100,
      ));
    }
    return days;
  }

  // Get hourly forecast
  Future<List<HourlyForecast>> getHourlyForecast(
      double lat, double lon) async {
    final url =
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=12';
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List list = json['list'] ?? [];
        return list.map((item) {
          return HourlyForecast(
            time: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
            temperature: (item['main']?['temp'] ?? 0).toDouble(),
            iconCode: item['weather']?[0]?['icon'] ?? '01d',
            description: item['weather']?[0]?['description'] ?? '',
            rainChance: ((item['pop'] ?? 0) as num).toDouble() * 100,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Search cities
  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final url =
        '$_geoUrl/direct?q=${Uri.encodeComponent(query)}&limit=10&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Get mock Philippines alerts (in production, connect to PAGASA API)
  List<WeatherAlert> getPhilippinesAlerts() {
    return [
      WeatherAlert(
        title: 'Flood Warning',
        description:
            'Flooding expected in low-lying areas due to continuous rainfall.',
        location: 'Camarines Norte',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now(),
      ),
      WeatherAlert(
        title: 'Tropical Storm Watch',
        description:
            'Tropical storm Pedring intensifying in Eastern Visayas. Expected to make landfall within 48 hours.',
        location: 'Eastern Visayas',
        severity: AlertSeverity.typhoon,
        timestamp: DateTime.now(),
      ),
      WeatherAlert(
        title: 'Extreme Heat Advisory',
        description:
            'Heat index may reach 42°C. Stay hydrated and avoid prolonged sun exposure.',
        location: 'Soccsksargen',
        severity: AlertSeverity.advisory,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
