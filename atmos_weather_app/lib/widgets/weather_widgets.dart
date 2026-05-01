import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import '../models/weather_model.dart';

// ── ATMOS Logo Search Bar ──────────────────────────────────────────────────────
class AtmosSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hint;
  final bool autofocus;

  const AtmosSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hint = 'Search location...',
    this.autofocus = false,
  });

  @override
  State<AtmosSearchBar> createState() => _AtmosSearchBarState();
}

class _AtmosSearchBarState extends State<AtmosSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 16),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) {
          setState(() {});
          widget.onChanged?.call(v);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

// ── Weather Icon Widget ────────────────────────────────────────────────────────
class WeatherIconWidget extends StatelessWidget {
  final String iconCode;
  final double size;

  const WeatherIconWidget({
    super.key,
    required this.iconCode,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: WeatherUtils.getWeatherIconUrl(iconCode),
      width: size,
      height: size,
      placeholder: (_, __) => Icon(
        Icons.wb_cloudy_rounded,
        size: size * 0.8,
        color: Colors.white,
      ),
      errorWidget: (_, __, ___) => Text(
        WeatherUtils.getWeatherEmoji(iconCode),
        style: TextStyle(fontSize: size * 0.7),
      ),
    );
  }
}

// ── Weather Metric Card ────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Hourly Forecast Item ───────────────────────────────────────────────────────
class HourlyForecastItem extends StatelessWidget {
  final HourlyForecast hourly;
  final bool isNow;

  const HourlyForecastItem({
    super.key,
    required this.hourly,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isNow
            ? Colors.white.withOpacity(0.3)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: isNow
            ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isNow ? 'Now' : WeatherUtils.formatHour(hourly.time),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 10,
              fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          WeatherIconWidget(iconCode: hourly.iconCode, size: 26),
          const SizedBox(height: 6),
          Text(
            WeatherUtils.formatTemp(hourly.temperature),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7-Day Forecast Row ─────────────────────────────────────────────────────────
class ForecastRow extends StatelessWidget {
  final ForecastDay day;
  final bool isFirst;
  final bool isLast;

  const ForecastRow({
    super.key,
    required this.day,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              WeatherUtils.getDayName(day.date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          WeatherIconWidget(iconCode: day.iconCode, size: 28),
          const SizedBox(width: 8),
          if (day.rainChance > 20)
            Text(
              '${day.rainChance.round()}%',
              style: const TextStyle(
                color: Color(0xFF90CAF9),
                fontSize: 12,
              ),
            ),
          const Spacer(),
          Text(
            WeatherUtils.formatTemp(day.tempMin),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: _TempBar(min: day.tempMin, max: day.tempMax),
          ),
          const SizedBox(width: 8),
          Text(
            WeatherUtils.formatTemp(day.tempMax),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempBar extends StatelessWidget {
  final double min;
  final double max;

  const _TempBar({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          colors: [Color(0xFF90CAF9), Color(0xFFF7B731)],
        ),
      ),
    );
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────────
class AlertCard extends StatelessWidget {
  final WeatherAlert alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = WeatherUtils.getAlertColor(alert.severity);
    final icon = WeatherUtils.getAlertIcon(alert.severity);
    final label = WeatherUtils.getAlertLabel(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.location,
                        style: const TextStyle(
                          color: AtmosTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      color: AtmosTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      color: AtmosTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
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

// ── Reminder Card ──────────────────────────────────────────────────────────────
class ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AtmosTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            reminder['icon'] ?? '📌',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'] ?? '',
                  style: const TextStyle(
                    color: AtmosTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder['body'] ?? '',
                  style: const TextStyle(
                    color: AtmosTheme.textSecondary,
                    fontSize: 12,
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

// ── Loading Shimmer ────────────────────────────────────────────────────────────
class WeatherLoadingWidget extends StatelessWidget {
  const WeatherLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading weather data...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Widget ───────────────────────────────────────────────────────────────
class WeatherErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const WeatherErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.white70, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Weather',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AtmosTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Metric Row (for View More screen) ───────────────────────────────────
class DetailMetricRow extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;

  const DetailMetricRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics
          .map((m) => Expanded(
                child: Column(
                  children: [
                    Icon(m['icon'] as IconData,
                        color: AtmosTheme.skyBlue, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      m['value'] as String,
                      style: const TextStyle(
                        color: AtmosTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      m['label'] as String,
                      style: const TextStyle(
                        color: AtmosTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
