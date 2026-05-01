import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_widgets.dart';

class ViewMoreScreen extends StatelessWidget {
  const ViewMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          final weather = provider.currentWeather;
          if (weather == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            decoration: AtmosTheme.backgroundDecoration,
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withAlpha(51),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Extended Forecast',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detailed Metrics
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withAlpha(31),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFFFFFFF).withAlpha(51)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _MetricItem(
                                      icon: Icons.thermostat_rounded,
                                      label: 'Feels Like',
                                      value: WeatherUtils.formatTempWithUnit(
                                          weather.feelsLike),
                                    ),
                                    _MetricItem(
                                      icon: Icons.wb_sunny_rounded,
                                      label: 'UV Index',
                                      value:
                                          '${weather.uvIndex} (${_uvLabel(weather.uvIndex)})',
                                    ),
                                    _MetricItem(
                                      icon: Icons.visibility_rounded,
                                      label: 'Visibility',
                                      value: WeatherUtils.formatVisibility(
                                          weather.visibility),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _MetricItem(
                                      icon: Icons.water_drop_rounded,
                                      label: 'Humidity',
                                      value: WeatherUtils.formatHumidity(
                                          weather.humidity),
                                    ),
                                    _MetricItem(
                                      icon: Icons.air_rounded,
                                      label: 'Wind',
                                      value: WeatherUtils.formatWindSpeed(
                                          weather.windSpeed),
                                    ),
                                    _MetricItem(
                                      icon: Icons.compress_rounded,
                                      label: 'Pressure',
                                      value: WeatherUtils.formatPressure(
                                          weather.pressure),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Reminders Today
                          const Text(
                            'Reminder Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...provider.contextReminders
                              .take(4)
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _ReminderToday(reminder: r),
                                  )),
                          const SizedBox(height: 20),

                          // Temperature Highlights
                          const Text(
                            'Temperature Highlights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _HighlightCard(
                                  label: 'Hottest Day',
                                  day: provider.hottestDay,
                                  isHot: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _HighlightCard(
                                  label: 'Coolest Day',
                                  day: provider.coolestDay,
                                  isHot: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 7-Day List
                          const Text(
                            '7-Day Forecast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withAlpha(31),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFFFFFFF).withAlpha(51)),
                            ),
                            child: Column(
                              children: provider.forecast
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => ForecastRow(
                                      day: e.value,
                                      isFirst: e.key == 0,
                                      isLast:
                                          e.key == provider.forecast.length - 1,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _uvLabel(int uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withAlpha(166),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToday extends StatelessWidget {
  final Map<String, dynamic> reminder;

  const _ReminderToday({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(51)),
      ),
      child: Row(
        children: [
          Text(reminder['icon'] ?? '📌', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder['body'] ?? '',
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF).withAlpha(191),
                    fontSize: 11,
                    height: 1.4,
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

class _HighlightCard extends StatelessWidget {
  final String label;
  final dynamic day;
  final bool isHot;

  const _HighlightCard({
    required this.label,
    required this.day,
    required this.isHot,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(
            isHot ? Icons.whatshot_rounded : Icons.ac_unit_rounded,
            color: isHot ? const Color(0xFFFF7043) : const Color(0xFF90CAF9),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isHot ? '${day.tempMax.round()}°C' : '${day.tempMin.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            WeatherUtils.getDayName(day.date),
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withAlpha(179),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
