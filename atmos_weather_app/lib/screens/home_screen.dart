import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        if (provider.status == WeatherStatus.loading ||
            provider.status == WeatherStatus.initial) {
          return const WeatherLoadingWidget();
        }
        if (provider.status == WeatherStatus.error) {
          return WeatherErrorWidget(
            message: provider.errorMessage,
            onRetry: provider.loadWeatherByLocation,
          );
        }
        if (provider.currentWeather == null) {
          return const WeatherLoadingWidget();
        }
        return _HomeBody(provider: provider);
      },
    );
  }
}

class _HomeBody extends StatefulWidget {
  final WeatherProvider provider;
  const _HomeBody({required this.provider});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final weather = provider.currentWeather!;
    final hourly = provider.hourlyForecast;
    final forecast = provider.forecast;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AtmosTheme.primaryBlue,
      displacement: 20,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Big Temperature Block ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),

                            // Location row under top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  '${weather.cityName}, ${weather.country}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Giant yellow temperature — matches wireframe
                            Text(
                              '${weather.temperature.round()}°',
                              style: const TextStyle(
                                color: Color(0xFFFDD835),
                                fontSize: 96,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Condition
                            Text(
                              _capitalize(weather.description),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Comfort level sub-label
                            Text(
                              weather.comfortLevel,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // ── Hourly Forecast Strip ─────────────────────────
                      if (hourly.isNotEmpty) ...[
                        SizedBox(
                          height: 96,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: hourly.length,
                            itemBuilder: (context, index) => HourlyForecastItem(
                              hourly: hourly[index],
                              isNow: index == 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 7-Day Forecast Table ──────────────────────────
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Column(
                          children: [
                            // Table header row
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 60), // date col
                                  SizedBox(width: 56), // day name col
                                  Spacer(),
                                  SizedBox(width: 30), // icon
                                  SizedBox(width: 10), // rain%
                                  SizedBox(width: 48), // low
                                  SizedBox(width: 36), // high
                                ],
                              ),
                            ),

                            // Rows
                            ...forecast.asMap().entries.map((e) {
                              return _ForecastTableRow(
                                day: e.value,
                                isLast: e.key == forecast.length - 1,
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _ExtendedForecast(
                    provider: provider,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageDot(active: _pageIndex == 0),
              const SizedBox(width: 6),
              _PageDot(active: _pageIndex == 1),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ExtendedForecast extends StatelessWidget {
  final WeatherProvider provider;
  const _ExtendedForecast({required this.provider});

  @override
  Widget build(BuildContext context) {
    final weather = provider.currentWeather!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'Extended Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          // Detailed Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _MetricItem(
                      icon: Icons.thermostat_rounded,
                      label: 'Feels Like',
                      value: WeatherUtils.formatTempWithUnit(weather.feelsLike),
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
                      value: WeatherUtils.formatVisibility(weather.visibility),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricItem(
                      icon: Icons.water_drop_rounded,
                      label: 'Humidity',
                      value: WeatherUtils.formatHumidity(weather.humidity),
                    ),
                    _MetricItem(
                      icon: Icons.air_rounded,
                      label: 'Wind',
                      value: WeatherUtils.formatWindSpeed(weather.windSpeed),
                    ),
                    _MetricItem(
                      icon: Icons.compress_rounded,
                      label: 'Pressure',
                      value: WeatherUtils.formatPressure(weather.pressure),
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
          ...provider.contextReminders.take(4).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReminderToday(reminder: r),
                ),
              ),
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
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: provider.forecast.asMap().entries.map(
                (e) {
                  return ForecastRow(
                    day: e.value,
                    isFirst: e.key == 0,
                    isLast: e.key == provider.forecast.length - 1,
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
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

class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withOpacity(0.9)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
    );
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
              color: Colors.white.withOpacity(0.65),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                    color: Colors.white.withOpacity(0.75),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single row in the 7-day forecast table ────────────────────────────────────
class _ForecastTableRow extends StatelessWidget {
  final dynamic day; // ForecastDay
  final bool isLast;

  const _ForecastTableRow({required this.day, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    // Format date as MM/DD
    final dateFmt = DateFormat('MM/dd').format(day.date);
    // Day label
    final dayLabel = WeatherUtils.getDayName(day.date);

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          // Date e.g. 03/09
          SizedBox(
            width: 44,
            child: Text(
              dateFmt,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
              ),
            ),
          ),
          // Day name e.g. Today
          SizedBox(
            width: 72,
            child: Text(
              dayLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Weather icon
          WeatherIconWidget(iconCode: day.iconCode, size: 26),
          const SizedBox(width: 4),

          // Rain chance (shown only if > 0, in blue like wireframe)
          SizedBox(
            width: 40,
            child: day.rainChance > 5
                ? Text(
                    '${day.rainChance.round()}%',
                    style: const TextStyle(
                      color: Color(0xFF90CAF9),
                      fontSize: 12,
                    ),
                  )
                : const SizedBox(),
          ),

          const Spacer(),

          // Low temp
          SizedBox(
            width: 28,
            child: Text(
              '${day.tempMin.round()}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),

          // High temp (bold white)
          SizedBox(
            width: 28,
            child: Text(
              '${day.tempMax.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
