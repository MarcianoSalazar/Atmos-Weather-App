// lib/presentation/widgets/weather/air_quality_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

class AirQualityCard extends StatelessWidget {
  final AirQualityModel airQuality;

  const AirQualityCard({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    final aqi = airQuality.current.europeanAqi;
    final aqiColor = WeatherUtils.getAQIColor(aqi);
    final aqiLabel = WeatherUtils.getAQILabel(aqi);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.air_rounded,
                    color: AppColors.white60, size: 16,),
                const SizedBox(width: 6),
                const Text(
                  'AIR QUALITY',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white60,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: aqiColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: aqiColor.withAlpha(128)),
                  ),
                  child: Text(
                    aqiLabel,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: aqiColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // AQI Index with gauge
            Row(
              children: [
                Text(
                  '$aqi',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: aqiColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'European AQI',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          color: AppColors.white60,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF4CAF50),
                                Color(0xFFFFEB3B),
                                Color(0xFFFF9800),
                                Color(0xFFFF5722),
                                Color(0xFF9C27B0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Good',
                              style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 10,
                                  color: AppColors.white60,),),
                          Text('Extreme',
                              style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 10,
                                  color: AppColors.white60,),),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pollutants grid
            Row(
              children: [
                _PollutantItem(
                    label: 'PM2.5',
                    value: airQuality.current.pm2_5.toStringAsFixed(1),),
                _PollutantItem(
                    label: 'PM10',
                    value: airQuality.current.pm10.toStringAsFixed(1),),
                _PollutantItem(
                    label: 'O₃',
                    value: airQuality.current.ozone.toStringAsFixed(1),),
                _PollutantItem(
                    label: 'NO₂',
                    value:
                        airQuality.current.nitrogenDioxide.toStringAsFixed(1),),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PollutantItem extends StatelessWidget {
  final String label;
  final String value;

  const _PollutantItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 11,
              color: AppColors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
