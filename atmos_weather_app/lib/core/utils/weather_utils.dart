// lib/core/utils/weather_utils.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WeatherUtils {
  WeatherUtils._();

  // WMO Weather Code to description
  static String getWeatherDescription(int code) {
    const Map<int, String> codes = {
      0: 'Clear Sky',
      1: 'Mainly Clear',
      2: 'Partly Cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Icy Fog',
      51: 'Light Drizzle',
      53: 'Moderate Drizzle',
      55: 'Heavy Drizzle',
      61: 'Slight Rain',
      63: 'Moderate Rain',
      65: 'Heavy Rain',
      71: 'Slight Snow',
      73: 'Moderate Snow',
      75: 'Heavy Snow',
      77: 'Snow Grains',
      80: 'Slight Showers',
      81: 'Moderate Showers',
      82: 'Violent Showers',
      85: 'Slight Snow Showers',
      86: 'Heavy Snow Showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm w/ Hail',
      99: 'Thunderstorm w/ Heavy Hail',
    };
    return codes[code] ?? 'Unknown';
  }

  // WMO code to icon (using weather_icons package naming convention)
  static String getWeatherIconAsset(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? '☀️' : '🌙';
    if (code == 1) return isDay ? '🌤️' : '🌤️';
    if (code == 2) return '⛅';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 55) return '🌦️';
    if (code >= 61 && code <= 65) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code >= 85 && code <= 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }

  // Lottie animation name for weather code
  static String getLottieAnimation(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? 'sunny' : 'night_clear';
    if (code <= 2) return isDay ? 'partly_cloudy' : 'night_partly_cloudy';
    if (code == 3) return 'cloudy';
    if (code == 45 || code == 48) return 'foggy';
    if (code >= 51 && code <= 67) return 'rainy';
    if (code >= 71 && code <= 77) return 'snowy';
    if (code >= 80 && code <= 82) return 'rainy';
    if (code >= 95) return 'thunderstorm';
    return 'sunny';
  }

  // Background gradient based on weather
  static LinearGradient getWeatherGradient(int code, {bool isDay = true}) {
    if (!isDay) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0A1A), Color(0xFF0A1628), Color(0xFF0D2137)],
      );
    }
    if (code == 0 || code == 1) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
      );
    }
    if (code == 2 || code == 3) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2A4A), Color(0xFF243B6A), Color(0xFF2D4A80)],
      );
    }
    if (code >= 51 && code <= 82) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1020), Color(0xFF0D1A30), Color(0xFF112240)],
      );
    }
    if (code >= 95) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050A10), Color(0xFF0A1020), Color(0xFF0D1A30)],
      );
    }
    return AppColors.skyGradient;
  }

  // Temperature color
  static Color getTempColor(double temp) {
    if (temp <= 0) return const Color(0xFF81D4FA);
    if (temp <= 10) return const Color(0xFF42A5F5);
    if (temp <= 20) return const Color(0xFF2196F3);
    if (temp <= 25) return const Color(0xFFFFEA00);
    if (temp <= 30) return const Color(0xFFFFD600);
    if (temp <= 35) return const Color(0xFFFFC107);
    if (temp <= 40) return const Color(0xFFFF9800);
    return const Color(0xFFFF5722);
  }

  // UV Index color and label
  static Color getUVColor(double uvi) {
    if (uvi <= 2) return const Color(0xFF4CAF50);
    if (uvi <= 5) return const Color(0xFFFFEB3B);
    if (uvi <= 7) return const Color(0xFFFF9800);
    if (uvi <= 10) return const Color(0xFFFF5722);
    return const Color(0xFF9C27B0);
  }

  static String getUVLabel(double uvi) {
    if (uvi <= 2) return 'Low';
    if (uvi <= 5) return 'Moderate';
    if (uvi <= 7) return 'High';
    if (uvi <= 10) return 'Very High';
    return 'Extreme';
  }

  // AQI color and label
  static Color getAQIColor(int aqi) {
    if (aqi <= 20) return const Color(0xFF4CAF50);
    if (aqi <= 40) return const Color(0xFF8BC34A);
    if (aqi <= 60) return const Color(0xFFFFEB3B);
    if (aqi <= 80) return const Color(0xFFFF9800);
    if (aqi <= 100) return const Color(0xFFFF5722);
    return const Color(0xFF9C27B0);
  }

  static String getAQILabel(int aqi) {
    if (aqi <= 20) return 'Good';
    if (aqi <= 40) return 'Fair';
    if (aqi <= 60) return 'Moderate';
    if (aqi <= 80) return 'Poor';
    if (aqi <= 100) return 'Very Poor';
    return 'Extremely Poor';
  }

  // Wind direction
  static String getWindDirection(double degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees / 22.5) + 0.5).toInt() % 16;
    return directions[index];
  }

  // Temperature conversion
  static double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  static String formatTemp(double celsius, {String unit = 'celsius'}) {
    if (unit == 'fahrenheit') {
      return '${celsiusToFahrenheit(celsius).round()}°F';
    }
    return '${celsius.round()}°C';
  }

  static String formatTempValue(double celsius, {String unit = 'celsius'}) {
    if (unit == 'fahrenheit') {
      return celsiusToFahrenheit(celsius).round().toString();
    }
    return celsius.round().toString();
  }

  // Wind speed conversion
  static String formatWindSpeed(double kmh, {String unit = 'kmh'}) {
    switch (unit) {
      case 'mph':
        return '${(kmh * 0.621371).round()} mph';
      case 'ms':
        return '${(kmh / 3.6).toStringAsFixed(1)} m/s';
      case 'knots':
        return '${(kmh * 0.539957).round()} kt';
      default:
        return '${kmh.round()} km/h';
    }
  }

  // Pressure conversion
  static String formatPressure(double hpa, {String unit = 'hpa'}) {
    switch (unit) {
      case 'inhg':
        return '${(hpa * 0.02953).toStringAsFixed(2)} inHg';
      case 'mmhg':
        return '${(hpa * 0.750062).round()} mmHg';
      default:
        return '${hpa.round()} hPa';
    }
  }

  // Visibility
  static String formatVisibility(double meters, {String unit = 'km'}) {
    if (unit == 'mi') {
      return '${(meters / 1609.34).toStringAsFixed(1)} mi';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Precipitation probability color
  static Color getPrecipColor(double pop) {
    if (pop <= 0.2) return const Color(0xFF64B5F6);
    if (pop <= 0.5) return const Color(0xFF2196F3);
    if (pop <= 0.8) return const Color(0xFF1565C0);
    return const Color(0xFF0D47A1);
  }

  // Moon phase
  static String getMoonPhaseIcon(double phase) {
    if (phase < 0.063) return '🌑';
    if (phase < 0.188) return '🌒';
    if (phase < 0.313) return '🌓';
    if (phase < 0.438) return '🌔';
    if (phase < 0.563) return '🌕';
    if (phase < 0.688) return '🌖';
    if (phase < 0.813) return '🌗';
    if (phase < 0.938) return '🌘';
    return '🌑';
  }

  static String getMoonPhaseName(double phase) {
    if (phase < 0.063) return 'New Moon';
    if (phase < 0.188) return 'Waxing Crescent';
    if (phase < 0.313) return 'First Quarter';
    if (phase < 0.438) return 'Waxing Gibbous';
    if (phase < 0.563) return 'Full Moon';
    if (phase < 0.688) return 'Waning Gibbous';
    if (phase < 0.813) return 'Third Quarter';
    if (phase < 0.938) return 'Waning Crescent';
    return 'New Moon';
  }

  // Format DateTime from unix timestamp
  static String formatTime(int unix, {bool use24h = false}) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    if (use24h) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  static String formatDayName(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  static String formatHour(String isoTime, {bool use24h = false}) {
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    if (use24h) {
      return '${dt.hour.toString().padLeft(2, '0')}:00';
    }
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour}$period';
  }

  // Get alert severity color
  static Color getAlertSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return const Color(0xFFB71C1C);
      case 'severe':
        return const Color(0xFFE53935);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'minor':
        return const Color(0xFFFFEB3B);
      default:
        return const Color(0xFF2196F3);
    }
  }

  // Get alert severity icon
  static String getAlertSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return '🚨';
      case 'severe':
        return '⚠️';
      case 'moderate':
        return '⚡';
      case 'minor':
        return 'ℹ️';
      default:
        return '📢';
    }
  }
}
