// lib/presentation/widgets/weather/hourly_forecast_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

class HourlyForecastWidget extends StatelessWidget {
  final HourlyOpenMeteo hourlyData;
  final AppSettings settings;

  const HourlyForecastWidget({
    super.key,
    required this.hourlyData,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Get next 24 hours
    final startIdx = hourlyData.time.indexWhere((t) {
      final dt = DateTime.tryParse(t);
      return dt != null &&
          dt.isAfter(now.subtract(const Duration(minutes: 30)));
    });

    final idx = startIdx < 0 ? 0 : startIdx;
    final endIdx = (idx + 24).clamp(0, hourlyData.time.length);

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
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.white60,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'HOURLY FORECAST',
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
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: endIdx - idx,
                itemBuilder: (context, i) {
                  final dataIdx = idx + i;
                  final time = hourlyData.time[dataIdx];
                  final temp = hourlyData.temperature2m[dataIdx];
                  final code = hourlyData.weatherCode[dataIdx];
                  final pop = hourlyData.precipitationProbability[dataIdx];
                  final dt = DateTime.tryParse(time);
                  final isCurrentHour =
                      dt?.hour == currentHour && dt?.day == now.day;

                  return _HourlyItem(
                    time: WeatherUtils.formatHour(time,
                        use24h: settings.use24HourFormat,),
                    temp: WeatherUtils.formatTempValue(temp,
                        unit: settings.temperatureUnit,),
                    emoji: WeatherUtils.getWeatherIconAsset(code),
                    pop: pop,
                    isNow: isCurrentHour && i == 0,
                    tempUnit: settings.temperatureUnit,
                    tempVal: temp,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  final String time;
  final String temp;
  final String emoji;
  final double pop;
  final bool isNow;
  final String tempUnit;
  final double tempVal;

  const _HourlyItem({
    required this.time,
    required this.temp,
    required this.emoji,
    required this.pop,
    required this.isNow,
    required this.tempUnit,
    required this.tempVal,
  });

  @override
  Widget build(BuildContext context) {
    final tempColor = WeatherUtils.getTempColor(tempVal);
    return Container(
      width: 64,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isNow
          ? BoxDecoration(
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.tempYellow.withAlpha(128)),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            isNow ? 'NOW' : time,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNow ? AppColors.tempYellow : AppColors.white60,
              letterSpacing: 0.5,
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(
            '$temp°',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tempColor,
            ),
          ),
          if (pop > 10)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop,
                    size: 10, color: AppColors.primaryBright,),
                const SizedBox(width: 2),
                Text(
                  '${pop.round()}%',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 10,
                    color: AppColors.primaryBright,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
