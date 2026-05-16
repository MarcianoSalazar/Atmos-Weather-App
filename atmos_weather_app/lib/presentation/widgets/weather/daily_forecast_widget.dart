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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      color: AppColors.white60, size: 16),
                  SizedBox(width: 6),
                  Text(
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
            Builder(
              builder: (context) {
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
                  separatorBuilder: (_, __) => const Divider(
                      color: AppColors.white10,
                      height: 1,
                      indent: 16,
                      endIndent: 16),
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
                      minTemp: WeatherUtils.formatTempValue(minTemp,
                          unit: settings.temperatureUnit),
                      maxTemp: WeatherUtils.formatTempValue(maxTemp,
                          unit: settings.temperatureUnit),
                      minTempVal: minTemp,
                      maxTempVal: maxTemp,
                      globalMin: globalMin,
                      globalMax: globalMax,
                      precipSum: pop,
                      settings: settings,
                    );
                  },
                );
              },
            ),
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
          // ── Day label — fixed width, never shrinks ──────────────────────
          SizedBox(
            width: 48,
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

          const SizedBox(width: 4),

          // ── Emoji — clamped to a fixed box so glyph metrics can't push ──
          // the row wider (emoji advance-width > fontSize on most platforms).
          SizedBox(
            width: 26,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
              overflow: TextOverflow.clip,
            ),
          ),

          const SizedBox(width: 4),

          // ── Precip — sits in a fixed-width box so it never steals space ─
          // from the temp bar on rainy days with long mm values.
          SizedBox(
            width: 52,
            child: precipSum > 0.1
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 11,
                        color: AppColors.primaryBright,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${precipSum.toStringAsFixed(1)}mm',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11,
                            color: AppColors.primaryBright,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Right section: min · bar · max — takes ALL remaining space ──
          // Expanded ensures the total row width is always == parent width,
          // regardless of screen size. The inner Row divides that space with
          // IntrinsicWidth temp labels and a flexible bar in the middle.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Min temp — right-aligned, fixed intrinsic width
                Text(
                  '$minTemp°',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    color: AppColors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Temperature bar — fills remaining space between the two
                // temp labels; LayoutBuilder reads the real pixel width so
                // the barStart/barEnd fractions are always accurate.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 6,
                      child: LayoutBuilder(
                        builder: (context, bc) {
                          final w = bc.maxWidth;
                          final left = (barStart * w).clamp(0.0, w);
                          final right =
                              ((1.0 - barEnd) * w).clamp(0.0, w - left);
                          return Stack(
                            children: [
                              // Track
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white10,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Colored range
                              Positioned(
                                left: left,
                                right: right,
                                top: 0,
                                bottom: 0,
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
                            ],
                          );
                        },
                      ),
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
          ),
        ],
      ),
    );
  }
}
  