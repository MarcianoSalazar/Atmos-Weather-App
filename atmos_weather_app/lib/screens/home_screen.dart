import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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

        return _WeatherShell(
          condition: provider.currentWeather!.mainCondition,
          child: _HomeBody(provider: provider),
        );
      },
    );
  }
}

class _WeatherShell extends StatelessWidget {
  final String condition;
  final Widget child;

  const _WeatherShell({required this.condition, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = _WeatherPalette.fromCondition(condition);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          _BackdropOrbs(palette: palette),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _BackdropOrbs extends StatelessWidget {
  final _WeatherPalette palette;
  const _BackdropOrbs({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _GlowOrb(color: palette.accent.withAlpha(64), size: 220),
        ),
        Positioned(
          top: 120,
          right: -70,
          child: _GlowOrb(color: palette.highlight.withAlpha(51), size: 200),
        ),
        Positioned(
          bottom: -90,
          left: -40,
          child: _GlowOrb(color: palette.base.withAlpha(51), size: 240),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
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
    final dateLabel = DateFormat('EEE, MMM d').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF000000).withAlpha(51),
      displacement: 16,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFFFFFFF).withAlpha(191),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              _HeroCard(weather: weather),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Today', subtitle: 'Quick metrics'),
              const SizedBox(height: 10),
              _QuickMetrics(weather: weather),
              const SizedBox(height: 20),
              if (hourly.isNotEmpty) ...[
                _SectionTitle(title: 'Hourly', subtitle: 'Next 12 hours'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: hourly.length,
                    itemBuilder: (context, index) => HourlyForecastItem(
                      hourly: hourly[index],
                      isNow: index == 0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _SectionTitle(title: '7-Day', subtitle: 'Weekly outlook'),
              const SizedBox(height: 10),
              _ForecastTable(forecast: forecast),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'Extended Forecast',
                subtitle: 'More details for the week',
              ),
              const SizedBox(height: 12),
              _ExtendedForecast(provider: provider),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic weather;
  const _HeroCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(41),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${weather.cityName}, ${weather.country}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeroIcon(iconCode: weather.iconCode),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        '${weather.temperature.round()}°',
                        key: ValueKey('${weather.temperature.round()}'),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _capitalize(weather.description),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.comfortLevel,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFFFFFFF).withAlpha(191),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _HeroIcon extends StatelessWidget {
  final String iconCode;
  const _HeroIcon({required this.iconCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(51),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(102)),
      ),
      child: Center(
        child: WeatherIconWidget(iconCode: iconCode, size: 48),
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  final dynamic weather;
  const _QuickMetrics({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricChip(
          icon: Icons.thermostat_rounded,
          label: 'Feels',
          value: WeatherUtils.formatTempWithUnit(weather.feelsLike),
        ),
        const SizedBox(width: 10),
        _MetricChip(
          icon: Icons.water_drop_rounded,
          label: 'Humidity',
          value: WeatherUtils.formatHumidity(weather.humidity),
        ),
        const SizedBox(width: 10),
        _MetricChip(
          icon: Icons.wb_sunny_rounded,
          label: 'UV',
          value: '${weather.uvIndex}',
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withAlpha(36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(64)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFFFFFF).withAlpha(179),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            color: const Color(0xFFFFFFFF).withAlpha(166),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ForecastTable extends StatelessWidget {
  final List<dynamic> forecast;
  const _ForecastTable({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(51)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 60),
                SizedBox(width: 56),
                Spacer(),
                SizedBox(width: 30),
                SizedBox(width: 10),
                SizedBox(width: 48),
                SizedBox(width: 36),
              ],
            ),
          ),
          ...forecast.asMap().entries.map((e) {
            return _ForecastTableRow(
              day: e.value,
              isLast: e.key == forecast.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _ExtendedForecast extends StatelessWidget {
  final WeatherProvider provider;
  const _ExtendedForecast({required this.provider});

  @override
  Widget build(BuildContext context) {
    final weather = provider.currentWeather!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withAlpha(31),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(51)),
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
                    value: '${weather.uvIndex} (${_uvLabel(weather.uvIndex)})',
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
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Reminder Today', subtitle: 'Stay ready'),
        const SizedBox(height: 10),
        ...provider.contextReminders.take(4).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ReminderToday(reminder: r),
              ),
            ),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Temperature Highlights',
          subtitle: 'Range insights',
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
        const SizedBox(height: 22),
        const _SectionTitle(title: '7-Day Forecast', subtitle: 'Full list'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withAlpha(31),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(51)),
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
      ],
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
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
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
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder['body'] ?? '',
                  style: GoogleFonts.montserrat(
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
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isHot ? '${day.tempMax.round()}°C' : '${day.tempMin.round()}°C',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            WeatherUtils.getDayName(day.date),
            style: GoogleFonts.montserrat(
              color: const Color(0xFFFFFFFF).withAlpha(179),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single row in the 7-day forecast table ─────────────────────────────────
class _ForecastTableRow extends StatelessWidget {
  final dynamic day; // ForecastDay
  final bool isLast;

  const _ForecastTableRow({required this.day, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MM/dd').format(day.date);
    final dayLabel = WeatherUtils.getDayName(day.date);

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                color: const Color(0xFFFFFFFF).withAlpha(26),
              ))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              dateFmt,
              style: GoogleFonts.montserrat(
                color: const Color(0xFFFFFFFF).withAlpha(191),
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              dayLabel,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          WeatherIconWidget(iconCode: day.iconCode, size: 26),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: day.rainChance > 5
                ? Text(
                    '${day.rainChance.round()}%',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF90CAF9),
                      fontSize: 12,
                    ),
                  )
                : const SizedBox(),
          ),
          const Spacer(),
          SizedBox(
            width: 28,
            child: Text(
              '${day.tempMin.round()}',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFFFFFFF).withAlpha(166),
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '${day.tempMax.round()}',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherPalette {
  final List<Color> gradient;
  final Color base;
  final Color accent;
  final Color highlight;

  const _WeatherPalette({
    required this.gradient,
    required this.base,
    required this.accent,
    required this.highlight,
  });

  factory _WeatherPalette.fromCondition(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('clear') || cond.contains('sun')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF2B6CB0), Color(0xFF7BC8FF)],
        base: const Color(0xFF2B6CB0),
        accent: const Color(0xFFFFD36A),
        highlight: const Color(0xFFFFF3B0),
      );
    }
    if (cond.contains('cloud')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF2F3B52), Color(0xFF7083A2)],
        base: const Color(0xFF2F3B52),
        accent: const Color(0xFFA4B6D6),
        highlight: const Color(0xFFCED9EB),
      );
    }
    if (cond.contains('rain') || cond.contains('drizzle')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF1F3550), Color(0xFF4B78A7)],
        base: const Color(0xFF1F3550),
        accent: const Color(0xFF7DB9FF),
        highlight: const Color(0xFFB9D9FF),
      );
    }
    if (cond.contains('thunder')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF1A1C2C), Color(0xFF4A4E6E)],
        base: const Color(0xFF1A1C2C),
        accent: const Color(0xFFFFD26E),
        highlight: const Color(0xFFE7C2FF),
      );
    }
    if (cond.contains('snow')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF4D6C8A), Color(0xFFB7D7F0)],
        base: const Color(0xFF4D6C8A),
        accent: const Color(0xFFFFFFFF),
        highlight: const Color(0xFFE6F4FF),
      );
    }
    if (cond.contains('mist') || cond.contains('fog')) {
      return _WeatherPalette(
        gradient: const [Color(0xFF3E4B5C), Color(0xFF9FB1C5)],
        base: const Color(0xFF3E4B5C),
        accent: const Color(0xFFBFD0E0),
        highlight: const Color(0xFFE2ECF3),
      );
    }
    return _WeatherPalette(
      gradient: const [Color(0xFF2B5876), Color(0xFF4E7AC7)],
      base: const Color(0xFF2B5876),
      accent: const Color(0xFF7BC8FF),
      highlight: const Color(0xFFF6F6F6),
    );
  }
}
