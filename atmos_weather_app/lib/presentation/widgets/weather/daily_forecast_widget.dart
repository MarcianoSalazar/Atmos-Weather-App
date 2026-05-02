// lib/presentation/widgets/weather/daily_forecast_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

class DailyForecastWidget extends StatelessWidget {
  final DailyOpenMeteo dailyData;
  final AppSettings settings;

  const DailyForecastWidget({
    super.key,
    required this.dailyData,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: AppColors.white60, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    '7-DAY FORECAST',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white60,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.white10, height: 1),

            // Get overall temp range for bar scaling
            Builder(builder: (context) {
              double globalMin = double.infinity;
              double globalMax = double.negativeInfinity;
              for (int i = 0; i < dailyData.time.length; i++) {
                final min = dailyData.temperature2mMin[i];
                final max = dailyData.temperature2mMax[i];
                if (min < globalMin) globalMin = min;
                if (max > globalMax) globalMax = max;
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyData.time.length.clamp(0, 7),
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.white10, height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, i) {
                  final time = dailyData.time[i];
                  final code = dailyData.weatherCode[i];
                  final minTemp = dailyData.temperature2mMin[i];
                  final maxTemp = dailyData.temperature2mMax[i];
                  final pop = dailyData.precipitationSum[i];
                  final isToday = i == 0;

                  return _DailyItem(
                    day: isToday ? 'Today' : WeatherUtils.formatDayName(time),
                    emoji: WeatherUtils.getWeatherIconAsset(code),
                    description: WeatherUtils.getWeatherDescription(code),
                    minTemp: WeatherUtils.formatTempValue(minTemp, unit: settings.temperatureUnit),
                    maxTemp: WeatherUtils.formatTempValue(maxTemp, unit: settings.temperatureUnit),
                    minTempVal: minTemp,
                    maxTempVal: maxTemp,
                    globalMin: globalMin,
                    globalMax: globalMax,
                    precipSum: pop,
                    settings: settings,
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DailyItem extends StatelessWidget {
  final String day;
  final String emoji;
  final String description;
  final String minTemp;
  final String maxTemp;
  final double minTempVal;
  final double maxTempVal;
  final double globalMin;
  final double globalMax;
  final double precipSum;
  final AppSettings settings;

  const _DailyItem({
    required this.day,
    required this.emoji,
    required this.description,
    required this.minTemp,
    required this.maxTemp,
    required this.minTempVal,
    required this.maxTempVal,
    required this.globalMin,
    required this.globalMax,
    required this.precipSum,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final range = globalMax - globalMin;
    final barStart = range > 0 ? (minTempVal - globalMin) / range : 0.0;
    final barEnd = range > 0 ? (maxTempVal - globalMin) / range : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Day
          SizedBox(
            width: 56,
            child: Text(
              day,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),

          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 22)),

          const SizedBox(width: 8),

          // Precip
          if (precipSum > 0.1) ...[
            const Icon(Icons.water_drop, size: 12, color: AppColors.primaryBright),
            const SizedBox(width: 2),
            Text(
              '${precipSum.toStringAsFixed(1)}mm',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                color: AppColors.primaryBright,
              ),
            ),
            const SizedBox(width: 4),
          ],

          const Spacer(),

          // Min temp
          Text(
            '$minTemp°',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              color: AppColors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Temperature bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: 80,
              height: 6,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Temp bar
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: barStart * 80,
                        right: (1 - barEnd) * 80,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              WeatherUtils.getTempColor(minTempVal),
                              WeatherUtils.getTempColor(maxTempVal),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Max temp
          Text(
            '$maxTemp°',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              color: AppColors.tempYellow,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
