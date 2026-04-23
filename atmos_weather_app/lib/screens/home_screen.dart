import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_widgets.dart';
import 'view_more_screen.dart';

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

class _HomeBody extends StatelessWidget {
  final WeatherProvider provider;
  const _HomeBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    final weather = provider.currentWeather!;
    final hourly = provider.hourlyForecast;
    final forecast = provider.forecast;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AtmosTheme.primaryBlue,
      displacement: 20,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Big Temperature Block ─────────────────────────────────────
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
                      color: Color(0xFFFDD835), // yellow like wireframe
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

            // ── Hourly Forecast Strip ─────────────────────────────────────
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

            // ── 7-Day Forecast Table ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                children: [
                  // Table header row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 60), // date col
                        const SizedBox(width: 56), // day name col
                        const Spacer(),
                        const SizedBox(width: 30), // icon
                        const SizedBox(width: 10), // rain%
                        const SizedBox(width: 48), // low
                        const SizedBox(width: 36), // high
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

            const SizedBox(height: 12),

            // ── View More link ────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ViewMoreScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'View more',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
