// lib/presentation/widgets/weather/weather_details_grid.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

class WeatherDetailsGrid extends StatelessWidget {
  final CurrentOpenMeteo current;
  final AppSettings settings;

  const WeatherDetailsGrid({
    super.key,
    required this.current,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.white60, size: 16),
                SizedBox(width: 6),
                Text(
                  'WEATHER DETAILS',
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _DetailCard(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${current.relativeHumidity2m.round()}%',
                subtitle: _getHumidityLabel(current.relativeHumidity2m.round()),
                color: const Color(0xFF64B5F6),
                progress: current.relativeHumidity2m / 100,
              ),
              _DetailCard(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: WeatherUtils.formatWindSpeed(current.windSpeed10m, unit: settings.windSpeedUnit),
                subtitle: WeatherUtils.getWindDirection(current.windDirection10m),
                color: const Color(0xFF81D4FA),
                customWidget: _WindDirectionDial(degrees: current.windDirection10m),
              ),
              _DetailCard(
                icon: Icons.compress_rounded,
                label: 'Pressure',
                value: WeatherUtils.formatPressure(current.surfacePressure, unit: settings.pressureUnit),
                subtitle: _getPressureLabel(current.surfacePressure),
                color: const Color(0xFF4FC3F7),
              ),
              _DetailCard(
                icon: Icons.visibility_rounded,
                label: 'Visibility',
                value: WeatherUtils.formatVisibility(
                  current.precipitation > 0 ? 5000 : 10000,
                  unit: settings.visibilityUnit,
                ),
                subtitle: 'Clear conditions',
                color: const Color(0xFF29B6F6),
              ),
              _DetailCard(
                icon: Icons.wb_cloudy_outlined,
                label: 'Cloud Cover',
                value: '${current.cloudCover}%',
                subtitle: _getCloudLabel(current.cloudCover),
                color: const Color(0xFFB0BEC5),
                progress: current.cloudCover / 100,
              ),
              _DetailCard(
                icon: Icons.grain_rounded,
                label: 'Precipitation',
                value: '${current.precipitation.toStringAsFixed(1)} mm',
                subtitle: current.precipitation > 0 ? 'Active now' : 'None',
                color: const Color(0xFF42A5F5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHumidityLabel(int humidity) {
    if (humidity < 30) return 'Very Dry';
    if (humidity < 40) return 'Dry';
    if (humidity < 60) return 'Comfortable';
    if (humidity < 75) return 'Humid';
    return 'Very Humid';
  }

  String _getPressureLabel(double hpa) {
    if (hpa < 1000) return 'Low pressure';
    if (hpa < 1013) return 'Below normal';
    if (hpa < 1020) return 'Normal';
    return 'High pressure';
  }

  String _getCloudLabel(int clouds) {
    if (clouds < 10) return 'Clear';
    if (clouds < 30) return 'Mostly clear';
    if (clouds < 60) return 'Partly cloudy';
    if (clouds < 90) return 'Mostly cloudy';
    return 'Overcast';
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final double? progress;
  final Widget? customWidget;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.progress,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white60,
                  letterSpacing: 1,
                ),
              ),
              if (customWidget != null) ...[
                const Spacer(),
                customWidget!,
              ],
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: AppColors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              color: AppColors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindDirectionDial extends StatelessWidget {
  final double degrees;

  const _WindDirectionDial({required this.degrees});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _DialPainter(degrees: degrees),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double degrees;

  const _DialPainter({required this.degrees});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.white10
        ..style = PaintingStyle.fill,
    );

    // Arrow
    final angle = (degrees - 90) * math.pi / 180;
    final arrowEnd = Offset(
      center.dx + (radius - 4) * math.cos(angle),
      center.dy + (radius - 4) * math.sin(angle),
    );

    canvas.drawLine(
      center,
      arrowEnd,
      Paint()
        ..color = AppColors.tempYellow
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 3, Paint()..color = AppColors.white60);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) => oldDelegate.degrees != degrees;
}
