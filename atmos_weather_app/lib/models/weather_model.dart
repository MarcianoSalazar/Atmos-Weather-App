class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String description;
  final String mainCondition;
  final String iconCode;
  final double humidity;
  final double windSpeed;
  final double pressure;
  final double visibility;
  final int uvIndex;
  final double lat;
  final double lon;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.lat,
    required this.lon,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      country: json['sys']?['country'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),
      tempMin: (json['main']?['temp_min'] ?? 0).toDouble(),
      tempMax: (json['main']?['temp_max'] ?? 0).toDouble(),
      description: json['weather']?[0]?['description'] ?? '',
      mainCondition: json['weather']?[0]?['main'] ?? '',
      iconCode: json['weather']?[0]?['icon'] ?? '01d',
      humidity: (json['main']?['humidity'] ?? 0).toDouble(),
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      pressure: (json['main']?['pressure'] ?? 0).toDouble(),
      visibility: ((json['visibility'] ?? 0) / 1000).toDouble(),
      uvIndex: 0,
      lat: (json['coord']?['lat'] ?? 0).toDouble(),
      lon: (json['coord']?['lon'] ?? 0).toDouble(),
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (json['sys']?['sunrise'] ?? 0) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (json['sys']?['sunset'] ?? 0) * 1000),
      timestamp: DateTime.now(),
    );
  }

  String get comfortLevel {
    if (temperature >= 35) return 'Very Hot';
    if (temperature >= 30) return 'Hot · Sunny';
    if (temperature >= 25) return 'Warm · Comfortable';
    if (temperature >= 20) return 'Pleasant';
    if (temperature >= 15) return 'Cool';
    return 'Cold';
  }

  WeatherData copyWith({
    int? uvIndex,
  }) {
    return WeatherData(
      cityName: cityName,
      country: country,
      temperature: temperature,
      feelsLike: feelsLike,
      tempMin: tempMin,
      tempMax: tempMax,
      description: description,
      mainCondition: mainCondition,
      iconCode: iconCode,
      humidity: humidity,
      windSpeed: windSpeed,
      pressure: pressure,
      visibility: visibility,
      uvIndex: uvIndex ?? this.uvIndex,
      lat: lat,
      lon: lon,
      sunrise: sunrise,
      sunset: sunset,
      timestamp: timestamp,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String description;
  final String mainCondition;
  final String iconCode;
  final double humidity;
  final double windSpeed;
  final double rainChance;

  ForecastDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.rainChance,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String iconCode;
  final String description;
  final double rainChance;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.iconCode,
    required this.description,
    required this.rainChance,
  });
}

class WeatherAlert {
  final String title;
  final String description;
  final String location;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String? radarImageUrl;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.timestamp,
    this.radarImageUrl,
  });
}

enum AlertSeverity { warning, alert, advisory, typhoon }
