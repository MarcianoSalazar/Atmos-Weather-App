// lib/data/models/weather_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherModel {
  final double lat;
  final double lon;
  final String timezone;
  final CurrentWeatherModel current;
  final List<HourlyWeatherModel> hourly;
  final List<DailyWeatherModel> daily;
  final List<WeatherAlertModel>? alerts;

  WeatherModel({
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.current,
    required this.hourly,
    required this.daily,
    this.alerts,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherModelToJson(this);
}

@JsonSerializable()
class CurrentWeatherModel {
  final int dt;
  final int? sunrise;
  final int? sunset;
  final double temp;
  @JsonKey(name: 'feels_like')
  final double feelsLike;
  final int pressure;
  final int humidity;
  @JsonKey(name: 'dew_point')
  final double dewPoint;
  final double uvi;
  final int clouds;
  final int visibility;
  @JsonKey(name: 'wind_speed')
  final double windSpeed;
  @JsonKey(name: 'wind_deg')
  final int windDeg;
  @JsonKey(name: 'wind_gust')
  final double? windGust;
  final List<WeatherConditionModel> weather;

  CurrentWeatherModel({
    required this.dt,
    this.sunrise,
    this.sunset,
    required this.temp,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.dewPoint,
    required this.uvi,
    required this.clouds,
    required this.visibility,
    required this.windSpeed,
    required this.windDeg,
    this.windGust,
    required this.weather,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) =>
      _$CurrentWeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentWeatherModelToJson(this);
}

@JsonSerializable()
class HourlyWeatherModel {
  final int dt;
  final double temp;
  @JsonKey(name: 'feels_like')
  final double feelsLike;
  final int pressure;
  final int humidity;
  final double uvi;
  final int clouds;
  final double pop;
  final double? rain;
  final double? snow;
  @JsonKey(name: 'wind_speed')
  final double windSpeed;
  @JsonKey(name: 'wind_deg')
  final int windDeg;
  final List<WeatherConditionModel> weather;

  HourlyWeatherModel({
    required this.dt,
    required this.temp,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.uvi,
    required this.clouds,
    required this.pop,
    this.rain,
    this.snow,
    required this.windSpeed,
    required this.windDeg,
    required this.weather,
  });

  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) =>
      _$HourlyWeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$HourlyWeatherModelToJson(this);
}

@JsonSerializable()
class DailyWeatherModel {
  final int dt;
  final int sunrise;
  final int sunset;
  final int moonrise;
  final int moonset;
  @JsonKey(name: 'moon_phase')
  final double moonPhase;
  final String summary;
  final DailyTempModel temp;
  @JsonKey(name: 'feels_like')
  final DailyFeelsLikeModel feelsLike;
  final int pressure;
  final int humidity;
  @JsonKey(name: 'dew_point')
  final double dewPoint;
  @JsonKey(name: 'wind_speed')
  final double windSpeed;
  @JsonKey(name: 'wind_deg')
  final int windDeg;
  @JsonKey(name: 'wind_gust')
  final double? windGust;
  final List<WeatherConditionModel> weather;
  final int clouds;
  final double pop;
  final double uvi;
  final double? rain;
  final double? snow;

  DailyWeatherModel({
    required this.dt,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.summary,
    required this.temp,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.dewPoint,
    required this.windSpeed,
    required this.windDeg,
    this.windGust,
    required this.weather,
    required this.clouds,
    required this.pop,
    required this.uvi,
    this.rain,
    this.snow,
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) =>
      _$DailyWeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyWeatherModelToJson(this);
}

@JsonSerializable()
class DailyTempModel {
  final double day;
  final double min;
  final double max;
  final double night;
  final double eve;
  final double morn;

  DailyTempModel({
    required this.day,
    required this.min,
    required this.max,
    required this.night,
    required this.eve,
    required this.morn,
  });

  factory DailyTempModel.fromJson(Map<String, dynamic> json) =>
      _$DailyTempModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyTempModelToJson(this);
}

@JsonSerializable()
class DailyFeelsLikeModel {
  final double day;
  final double night;
  final double eve;
  final double morn;

  DailyFeelsLikeModel({
    required this.day,
    required this.night,
    required this.eve,
    required this.morn,
  });

  factory DailyFeelsLikeModel.fromJson(Map<String, dynamic> json) =>
      _$DailyFeelsLikeModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyFeelsLikeModelToJson(this);
}

@JsonSerializable()
class WeatherConditionModel {
  final int id;
  final String main;
  final String description;
  final String icon;

  WeatherConditionModel({
    required this.id,
    required this.main,
    required this.description,
    required this.icon,
  });

  factory WeatherConditionModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherConditionModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherConditionModelToJson(this);
}

@JsonSerializable()
class WeatherAlertModel {
  @JsonKey(name: 'sender_name')
  final String senderName;
  final String event;
  final int start;
  final int end;
  final String description;
  final List<String> tags;

  WeatherAlertModel({
    required this.senderName,
    required this.event,
    required this.start,
    required this.end,
    required this.description,
    required this.tags,
  });

  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherAlertModelToJson(this);
}

// Open-Meteo Model (no API key required)
class OpenMeteoModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentOpenMeteo? current;
  final HourlyOpenMeteo? hourly;
  final DailyOpenMeteo? daily;

  OpenMeteoModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.current,
    this.hourly,
    this.daily,
  });

  factory OpenMeteoModel.fromJson(Map<String, dynamic> json) {
    return OpenMeteoModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      current: json['current'] != null
          ? CurrentOpenMeteo.fromJson(json['current'] as Map<String, dynamic>)
          : null,
      hourly: json['hourly'] != null
          ? HourlyOpenMeteo.fromJson(json['hourly'] as Map<String, dynamic>)
          : null,
      daily: json['daily'] != null
          ? DailyOpenMeteo.fromJson(json['daily'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CurrentOpenMeteo {
  final String time;
  final double temperature2m;
  final double relativeHumidity2m;
  final double apparentTemperature;
  final int isDay;
  final double precipitation;
  final int weatherCode;
  final int cloudCover;
  final double windSpeed10m;
  final double windDirection10m;
  final double surfacePressure;

  CurrentOpenMeteo({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.isDay,
    required this.precipitation,
    required this.weatherCode,
    required this.cloudCover,
    required this.windSpeed10m,
    required this.windDirection10m,
    required this.surfacePressure,
  });

  factory CurrentOpenMeteo.fromJson(Map<String, dynamic> json) {
    return CurrentOpenMeteo(
      time: json['time'] as String? ?? '',
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m:
          (json['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      isDay: (json['is_day'] as num?)?.toInt() ?? 1,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      cloudCover: (json['cloud_cover'] as num?)?.toInt() ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      windDirection10m: (json['wind_direction_10m'] as num?)?.toDouble() ?? 0.0,
      surfacePressure: (json['surface_pressure'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HourlyOpenMeteo {
  final List<String> time;
  final List<double> temperature2m;
  final List<double> precipitationProbability;
  final List<int> weatherCode;
  final List<double> windSpeed10m;
  final List<double> relativeHumidity2m;
  final List<double> uvIndex;

  HourlyOpenMeteo({
    required this.time,
    required this.temperature2m,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.relativeHumidity2m,
    required this.uvIndex,
  });

  factory HourlyOpenMeteo.fromJson(Map<String, dynamic> json) {
    List<double> toDoubleList(dynamic data) =>
        (data as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ??
        [];

    List<int> toIntList(dynamic data) =>
        (data as List<dynamic>?)
            ?.map((e) => (e as num?)?.toInt() ?? 0)
            .toList() ??
        [];

    return HourlyOpenMeteo(
      time: (json['time'] as List<dynamic>?)?.cast<String>() ?? [],
      temperature2m: toDoubleList(json['temperature_2m']),
      precipitationProbability: toDoubleList(json['precipitation_probability']),
      weatherCode: toIntList(json['weather_code']),
      windSpeed10m: toDoubleList(json['wind_speed_10m']),
      relativeHumidity2m: toDoubleList(json['relative_humidity_2m']),
      uvIndex: toDoubleList(json['uv_index']),
    );
  }
}

class DailyOpenMeteo {
  final List<String> time;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;
  final List<int> weatherCode;
  final List<double> precipitationSum;
  final List<double> windSpeed10mMax;
  final List<double> uvIndexMax;
  final List<String> sunrise;
  final List<String> sunset;

  DailyOpenMeteo({
    required this.time,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.weatherCode,
    required this.precipitationSum,
    required this.windSpeed10mMax,
    required this.uvIndexMax,
    required this.sunrise,
    required this.sunset,
  });

  factory DailyOpenMeteo.fromJson(Map<String, dynamic> json) {
    List<double> toDoubleList(dynamic data) =>
        (data as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ??
        [];

    List<int> toIntList(dynamic data) =>
        (data as List<dynamic>?)
            ?.map((e) => (e as num?)?.toInt() ?? 0)
            .toList() ??
        [];

    return DailyOpenMeteo(
      time: (json['time'] as List<dynamic>?)?.cast<String>() ?? [],
      temperature2mMax: toDoubleList(json['temperature_2m_max']),
      temperature2mMin: toDoubleList(json['temperature_2m_min']),
      weatherCode: toIntList(json['weather_code']),
      precipitationSum: toDoubleList(json['precipitation_sum']),
      windSpeed10mMax: toDoubleList(json['wind_speed_10m_max']),
      uvIndexMax: toDoubleList(json['uv_index_max']),
      sunrise: (json['sunrise'] as List<dynamic>?)?.cast<String>() ?? [],
      sunset: (json['sunset'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

// Air Quality Model
class AirQualityModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentAirQuality current;

  AirQualityModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    return AirQualityModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      current:
          CurrentAirQuality.fromJson(json['current'] as Map<String, dynamic>),
    );
  }
}

class CurrentAirQuality {
  final String time;
  final int europeanAqi;
  final double pm10;
  final double pm2_5;
  final double carbonMonoxide;
  final double nitrogenDioxide;
  final double sulphurDioxide;
  final double ozone;
  final double dust;
  final double uvIndex;

  CurrentAirQuality({
    required this.time,
    required this.europeanAqi,
    required this.pm10,
    required this.pm2_5,
    required this.carbonMonoxide,
    required this.nitrogenDioxide,
    required this.sulphurDioxide,
    required this.ozone,
    required this.dust,
    required this.uvIndex,
  });

  factory CurrentAirQuality.fromJson(Map<String, dynamic> json) {
    return CurrentAirQuality(
      time: json['time'] as String? ?? '',
      europeanAqi: (json['european_aqi'] as num?)?.toInt() ?? 0,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 0.0,
      pm2_5: (json['pm2_5'] as num?)?.toDouble() ?? 0.0,
      carbonMonoxide: (json['carbon_monoxide'] as num?)?.toDouble() ?? 0.0,
      nitrogenDioxide: (json['nitrogen_dioxide'] as num?)?.toDouble() ?? 0.0,
      sulphurDioxide: (json['sulphur_dioxide'] as num?)?.toDouble() ?? 0.0,
      ozone: (json['ozone'] as num?)?.toDouble() ?? 0.0,
      dust: (json['dust'] as num?)?.toDouble() ?? 0.0,
      uvIndex: (json['uv_index'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Saved Location Model
class SavedLocation {
  final String id;
  final String name;
  final String country;
  final String? state;
  /// Province/district level — shown in the UI as the location subtitle.
  final String? admin2;
  final double lat;
  final double lon;
  final bool isHome;
  final DateTime savedAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.country,
    this.state,
    this.admin2,
    required this.lat,
    required this.lon,
    required this.isHome,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'state': state,
        'admin2': admin2,
        'lat': lat,
        'lon': lon,
        'isHome': isHome,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
        state: json['state'] as String?,
        admin2: json['admin2'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        isHome: json['isHome'] as bool,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );

  SavedLocation copyWith({
    String? id,
    String? name,
    String? country,
    String? state,
    String? admin2,
    double? lat,
    double? lon,
    bool? isHome,
    DateTime? savedAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      state: state ?? this.state,
      admin2: admin2 ?? this.admin2,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      isHome: isHome ?? this.isHome,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}

// Geocoding Model
class GeocodingResult {
  final String name;
  final double lat;
  final double lon;
  final String country;
  /// admin1 — region level (e.g. "Calabarzon", "NCR"). Kept for internal use
  /// but never shown directly in the UI.
  final String? state;
  /// admin2 — province/district level (e.g. "Laguna", "Batangas", "England").
  /// This is what gets displayed as the subtitle in search results.
  final String? admin2;
  final String? localNames;

  GeocodingResult({
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
    this.state,
    this.admin2,
    this.localNames,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      country: json['country'] as String,
      state: json['state'] as String?,
      admin2: json['admin2'] as String?,
      localNames: json['local_names'] as String?,
    );
  }
}

// Weather Alert Local Model
class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String event;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isRead;
  final double lat;
  final double lon;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.event,
    required this.startsAt,
    required this.endsAt,
    required this.isRead,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity,
        'event': event,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'isRead': isRead,
        'lat': lat,
        'lon': lon,
      };

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        severity: json['severity'] as String,
        event: json['event'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        isRead: json['isRead'] as bool,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );

  WeatherAlert copyWith({bool? isRead}) {
    return WeatherAlert(
      id: id,
      title: title,
      description: description,
      severity: severity,
      event: event,
      startsAt: startsAt,
      endsAt: endsAt,
      isRead: isRead ?? this.isRead,
      lat: lat,
      lon: lon,
    );
  }
}

// App Settings Model
class AppSettings {
  final String temperatureUnit; // celsius, fahrenheit
  final String windSpeedUnit; // kmh, mph, ms, knots
  final String pressureUnit; // hpa, inhg, mmhg
  final String visibilityUnit; // km, mi
  final bool notifications;
  final bool severeAlertNotifications;
  final bool dailySummaryNotifications;
  final bool precipitationNotifications;
  final String theme; // dark, light, auto
  final bool use24HourFormat;
  final bool showAQI;
  final bool showUVIndex;
  final String mapStyle; // dark, light, satellite
  final String language;

  AppSettings({
    this.temperatureUnit = 'celsius',
    this.windSpeedUnit = 'kmh',
    this.pressureUnit = 'hpa',
    this.visibilityUnit = 'km',
    this.notifications = true,
    this.severeAlertNotifications = true,
    this.dailySummaryNotifications = false,
    this.precipitationNotifications = true,
    this.theme = 'dark',
    this.use24HourFormat = false,
    this.showAQI = true,
    this.showUVIndex = true,
    this.mapStyle = 'dark',
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
        'temperatureUnit': temperatureUnit,
        'windSpeedUnit': windSpeedUnit,
        'pressureUnit': pressureUnit,
        'visibilityUnit': visibilityUnit,
        'notifications': notifications,
        'severeAlertNotifications': severeAlertNotifications,
        'dailySummaryNotifications': dailySummaryNotifications,
        'precipitationNotifications': precipitationNotifications,
        'theme': theme,
        'use24HourFormat': use24HourFormat,
        'showAQI': showAQI,
        'showUVIndex': showUVIndex,
        'mapStyle': mapStyle,
        'language': language,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        temperatureUnit: json['temperatureUnit'] as String? ?? 'celsius',
        windSpeedUnit: json['windSpeedUnit'] as String? ?? 'kmh',
        pressureUnit: json['pressureUnit'] as String? ?? 'hpa',
        visibilityUnit: json['visibilityUnit'] as String? ?? 'km',
        notifications: json['notifications'] as bool? ?? true,
        severeAlertNotifications:
            json['severeAlertNotifications'] as bool? ?? true,
        dailySummaryNotifications:
            json['dailySummaryNotifications'] as bool? ?? false,
        precipitationNotifications:
            json['precipitationNotifications'] as bool? ?? true,
        theme: json['theme'] as String? ?? 'dark',
        use24HourFormat: json['use24HourFormat'] as bool? ?? false,
        showAQI: json['showAQI'] as bool? ?? true,
        showUVIndex: json['showUVIndex'] as bool? ?? true,
        mapStyle: json['mapStyle'] as String? ?? 'dark',
        language: json['language'] as String? ?? 'en',
      );

  AppSettings copyWith({
    String? temperatureUnit,
    String? windSpeedUnit,
    String? pressureUnit,
    String? visibilityUnit,
    bool? notifications,
    bool? severeAlertNotifications,
    bool? dailySummaryNotifications,
    bool? precipitationNotifications,
    String? theme,
    bool? use24HourFormat,
    bool? showAQI,
    bool? showUVIndex,
    String? mapStyle,
    String? language,
  }) {
    return AppSettings(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      windSpeedUnit: windSpeedUnit ?? this.windSpeedUnit,
      pressureUnit: pressureUnit ?? this.pressureUnit,
      visibilityUnit: visibilityUnit ?? this.visibilityUnit,
      notifications: notifications ?? this.notifications,
      severeAlertNotifications:
          severeAlertNotifications ?? this.severeAlertNotifications,
      dailySummaryNotifications:
          dailySummaryNotifications ?? this.dailySummaryNotifications,
      precipitationNotifications:
          precipitationNotifications ?? this.precipitationNotifications,
      theme: theme ?? this.theme,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      showAQI: showAQI ?? this.showAQI,
      showUVIndex: showUVIndex ?? this.showUVIndex,
      mapStyle: mapStyle ?? this.mapStyle,
      language: language ?? this.language,
    );
  }
}