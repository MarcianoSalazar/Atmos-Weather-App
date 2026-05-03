// lib/presentation/widgets/weather/current_weather_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

class CurrentWeatherCard extends StatelessWidget {
  final CurrentOpenMeteo current;
  final String cityName;
  final int weatherCode;
  final bool isDay;
  final AppSettings settings;

  const CurrentWeatherCard({
    super.key,
    required this.current,
    required this.cityName,
    required this.weatherCode,
    required this.isDay,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          // Main temperature display
          _buildMainTemp(),
          const SizedBox(height: 16),
          // Quick stats row
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildMainTemp() {
    final emoji = WeatherUtils.getWeatherIconAsset(weatherCode, isDay: isDay);
    final description = WeatherUtils.getWeatherDescription(weatherCode);
    final tempValue = WeatherUtils.formatTempValue(current.temperature2m, unit: settings.temperatureUnit);
    final feelsLike = WeatherUtils.formatTemp(current.apparentTemperature, unit: settings.temperatureUnit);

    return Column(
      children: [
        // Weather emoji/icon
        Text(emoji, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 4),

        // Temperature - large and yellow
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.tempGradient.createShader(bounds),
              child: Text(
                tempValue,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 110,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1.0,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                '°',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 60,
                  fontWeight: FontWeight.w300,
                  color: AppColors.tempYellow,
                ),
              ),
            ),
          ],
        ),

        // Weather description
        Text(
          description.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white80,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 8),

        // Feels like
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.thermostat_rounded, color: AppColors.white60, size: 16),
            const SizedBox(width: 4),
            Text(
              'Feels like $feelsLike',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 15,
                color: AppColors.white60,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _QuickStatItem(
          icon: Icons.water_drop_outlined,
          label: 'Humidity',
          value: '${current.relativeHumidity2m.round()}%',
          color: const Color(0xFF64B5F6),
        ),
        _QuickStatDivider(),
        _QuickStatItem(
          icon: Icons.air_rounded,
          label: 'Wind',
          value: WeatherUtils.formatWindSpeed(current.windSpeed10m, unit: settings.windSpeedUnit),
          color: const Color(0xFF81D4FA),
        ),
        _QuickStatDivider(),
        _QuickStatItem(
          icon: Icons.compress_rounded,
          label: 'Pressure',
          value: WeatherUtils.formatPressure(current.surfacePressure, unit: settings.pressureUnit),
          color: const Color(0xFF4FC3F7),
        ),
      ],
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                color: AppColors.white60,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 8);
}
