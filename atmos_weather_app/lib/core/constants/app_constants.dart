// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ATMOS';
  static const String appVersion = '1.0.0';

  // API Keys - Replace with your actual keys
  static const String openWeatherApiKey = 'e8a83f5133b0cbac5b85eb65a806fdab';
  static const String weatherApiKey = 'YOUR_WEATHERAPI_COM_KEY';
  static const String airQualityApiKey = 'YOUR_IQAIR_API_KEY';
  static const String mapboxToken = 'YOUR_MAPBOX_PUBLIC_TOKEN';
  static const String geoapifyApiKey = '86e1698c6d9947a3ba184ae539259efd';
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // OpenWeatherMap Endpoints
  static const String owmBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String owmGeoUrl = 'https://api.openweathermap.org/geo/1.0';
  static const String owmOneCallUrl = 'https://api.openweathermap.org/data/3.0';

  // WeatherAPI Endpoints
  static const String weatherApiBaseUrl = 'https://api.weatherapi.com/v1';

  // Open-Meteo (Free, No Key Required)
  static const String openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoAirQualityUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String openMeteoMarineUrl =
      'https://marine-api.open-meteo.com/v1/marine';

  // Map Tile URLs
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String stamenTonerTileUrl =
      'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png';
  static const String cartoDarkTileUrl =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  static const String cartoLightTileUrl =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
  static const String esriWorldImageryTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String openWeatherMapTileUrl =
      'https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.png?appid=$openWeatherApiKey';

  // Cache Keys
  static const String currentWeatherCache = 'current_weather';
  static const String hourlyForecastCache = 'hourly_forecast';
  static const String dailyForecastCache = 'daily_forecast';
  static const String savedLocationsKey = 'saved_locations';
  static const String settingsKey = 'app_settings';
  static const String alertsKey = 'weather_alerts';

  // Cache Duration
  static const Duration weatherCacheDuration = Duration(minutes: 15);
  static const Duration forecastCacheDuration = Duration(hours: 1);

  // Default Location (Manila, Philippines)
  static const double defaultLat = 14.5995;
  static const double defaultLon = 120.9842;
  static const String defaultCity = 'Manila';
  static const String defaultCountry = 'PH';

  // Weather Conditions
  static const Map<String, String> weatherConditionIcons = {
    'clear sky': 'clear',
    'few clouds': 'partly_cloudy',
    'scattered clouds': 'cloudy',
    'broken clouds': 'cloudy',
    'shower rain': 'rain',
    'rain': 'rain',
    'thunderstorm': 'thunderstorm',
    'snow': 'snow',
    'mist': 'mist',
    'fog': 'fog',
  };

  // Air Quality Index Levels
  static const Map<int, String> aqiLevels = {
    1: 'Good',
    2: 'Fair',
    3: 'Moderate',
    4: 'Poor',
    5: 'Very Poor',
  };

  // UV Index Levels
  static const Map<String, List<int>> uvIndexLevels = {
    'Low': [0, 2],
    'Moderate': [3, 5],
    'High': [6, 7],
    'Very High': [8, 10],
    'Extreme': [11, 20],
  };
}
