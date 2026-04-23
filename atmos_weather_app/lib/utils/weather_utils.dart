import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WeatherUtils {
  // Map OpenWeatherMap icon codes to emoji or local asset
  static String getWeatherEmoji(String iconCode) {
    final code = iconCode.replaceAll('n', 'd');
    switch (code) {
      case '01d': return '☀️';
      case '02d': return '⛅';
      case '03d': return '🌥️';
      case '04d': return '☁️';
      case '09d': return '🌧️';
      case '10d': return '🌦️';
      case '11d': return '⛈️';
      case '13d': return '❄️';
      case '50d': return '🌫️';
      default: return '🌤️';
    }
  }

  static IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny_rounded;
      case 'clouds': return Icons.cloud_rounded;
      case 'rain': return Icons.grain_rounded;
      case 'drizzle': return Icons.water_drop_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      case 'snow': return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog': return Icons.blur_on_rounded;
      default: return Icons.wb_cloudy_rounded;
    }
  }

  static Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return const Color(0xFFF7B731);
      case 'clouds': return const Color(0xFF778CA3);
      case 'rain':
      case 'drizzle': return const Color(0xFF4A9FD4);
      case 'thunderstorm': return const Color(0xFF4B6584);
      case 'snow': return const Color(0xFFD1E8FF);
      default: return AtmosTheme.primaryBlue;
    }
  }

  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static String formatTemp(double temp) {
    return '${temp.round()}°';
  }

  static String formatTempWithUnit(double temp) {
    return '${temp.round()}°C';
  }

  static String formatWindSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} km/h';
  }

  static String formatHumidity(double humidity) {
    return '${humidity.round()}%';
  }

  static String formatPressure(double pressure) {
    return '${pressure.round()} hPa';
  }

  static String formatVisibility(double visibility) {
    return '${visibility.toStringAsFixed(1)} km';
  }

  static String getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  static String getFullDayName(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday - 1];
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String formatHour(DateTime time) {
    final hour = time.hour;
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  static Color getAlertColor(dynamic severity) {
    switch (severity.toString()) {
      case 'AlertSeverity.warning': return const Color(0xFFE53935);
      case 'AlertSeverity.typhoon': return const Color(0xFFB71C1C);
      case 'AlertSeverity.advisory': return const Color(0xFFF57C00);
      default: return const Color(0xFFF9A825);
    }
  }

  static IconData getAlertIcon(dynamic severity) {
    switch (severity.toString()) {
      case 'AlertSeverity.warning': return Icons.warning_rounded;
      case 'AlertSeverity.typhoon': return Icons.cyclone_rounded;
      case 'AlertSeverity.advisory': return Icons.info_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  static String getAlertLabel(dynamic severity) {
    switch (severity.toString()) {
      case 'AlertSeverity.warning': return 'WARNING';
      case 'AlertSeverity.typhoon': return 'TYPHOON WATCH';
      case 'AlertSeverity.advisory': return 'ADVISORY';
      default: return 'ALERT';
    }
  }
}
