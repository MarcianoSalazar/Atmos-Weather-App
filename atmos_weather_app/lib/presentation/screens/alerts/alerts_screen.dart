import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../bloc/weather/weather_bloc.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<WeatherAlert> _storedAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = context.read<WeatherRepository>().getStoredAlerts();
    if (!mounted) return;
    setState(() {
      _storedAlerts = alerts;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    context.read<WeatherBloc>().add(const RefreshWeather());
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _loadAlerts();
  }

  Future<void> _markAsRead(WeatherAlert alert) async {
    if (alert.isRead) return;
    await context.read<WeatherRepository>().markAlertRead(alert.id);
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        final snapshot = _extractWeatherSnapshot(state);
        final generatedAlerts = snapshot.current == null
            ? <WeatherAlert>[]
            : _buildWeatherAdvisories(
                weather: snapshot.current!,
                lat: snapshot.lat,
                lon: snapshot.lon,
                cityName: snapshot.cityName,
                countryCode: snapshot.countryCode,
              );

        final alerts = <WeatherAlert>[..._storedAlerts, ...generatedAlerts]
          ..sort((a, b) {
            if (a.isRead != b.isRead) {
              return a.isRead ? 1 : -1;
            }
            return b.startsAt.compareTo(a.startsAt);
          });

        final unreadCount = alerts.where((alert) => !alert.isRead).length;

        return Scaffold(
          backgroundColor: AppColors.primaryDeep,
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.skyGradient),
            child: SafeArea(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.tempYellow,),
                    )
                  : RefreshIndicator(
                      color: AppColors.tempYellow,
                      backgroundColor: AppColors.primaryDark,
                      onRefresh: _refresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(
                              unreadCount: unreadCount,
                              cityName: snapshot.cityName,
                              countryCode: snapshot.countryCode,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Active Alerts',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (alerts.isEmpty)
                              _buildEmptyState()
                            else
                              ...alerts.map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AlertCard(
                                    alert: alert,
                                    onTap: () => _markAsRead(alert),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              'Reminders & Preparedness',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (alerts
                                .any((alert) => alert.severity == 'severe'))
                              _buildPreparednessPanel(
                                title: 'Go-Bag Checklist',
                                icon: Icons.backpack_rounded,
                                items: const [
                                  'Drinking water (3 days)',
                                  'Non-perishable food',
                                  'First aid kit & medicines',
                                  'Flashlight & spare batteries',
                                  'Portable radio / powerbank',
                                  'Important documents in a waterproof bag',
                                  'Extra clothing & sturdy shoes',
                                ],
                              ),
                            if (snapshot.current != null &&
                                snapshot.current!.temperature2m >= 30)
                              _buildPreparednessPanel(
                                title: 'Heat Index Reminders',
                                icon: Icons.wb_sunny_rounded,
                                items: const [
                                  'Carry water & stay hydrated',
                                  'Wear sunscreen & a hat',
                                  'Use shade when possible',
                                ],
                              ),
                            _buildInfoCard(
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Hotlines',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      color: AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  _HotlineRow(
                                    label: 'Disaster Hotline',
                                    number: 'Not available',
                                  ),
                                  _HotlineRow(
                                    label: 'Ambulance',
                                    number: 'Not available',
                                  ),
                                  _HotlineRow(
                                    label: 'Police',
                                    number: 'Not available',
                                  ),
                                  _HotlineRow(
                                    label: 'Fire Department',
                                    number: 'Not available',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Evacuation Tips',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      color: AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _Bullet(
                                    text:
                                        'Stay calm, follow alerts, and proceed to the nearest evacuation center.',
                                  ),
                                  _Bullet(
                                    text:
                                        'Bring your emergency kit and important documents.',
                                  ),
                                  _Bullet(
                                    text:
                                        'Assist children, elderly, and pets during evacuation.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Power Outage Kit',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      color: AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _SimpleChecklist(
                                    items: [
                                      'Batteries & flashlight',
                                      'Candles & lighter',
                                      'Portable radio',
                                      'Powerbank & charging cables',
                                      'Spare cash',
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.white60,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Weather alerts are location-aware. Reopen the app or refresh after searching a new city to update the alert list.',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        color: AppColors.white
                                            .withValues(alpha: 191),
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  _WeatherSnapshot _extractWeatherSnapshot(WeatherState state) {
    if (state is WeatherLoaded) {
      return _WeatherSnapshot(
        current: state.weather.current,
        cityName: state.cityName,
        countryCode: state.countryCode,
        lat: state.lat,
        lon: state.lon,
      );
    }

    if (state is WeatherRefreshing) {
      return _WeatherSnapshot(
        current: state.weather.current,
        cityName: state.cityName,
        countryCode: '',
        lat: state.lat,
        lon: state.lon,
      );
    }

    return const _WeatherSnapshot(
      current: null,
      cityName: 'Your Location',
      countryCode: '',
      lat: 0,
      lon: 0,
    );
  }

  List<WeatherAlert> _buildWeatherAdvisories({
    required CurrentOpenMeteo weather,
    required double lat,
    required double lon,
    required String cityName,
    required String countryCode,
  }) {
    final now = DateTime.now();
    final location =
        countryCode.isNotEmpty ? '$cityName, $countryCode' : cityName;
    final alerts = <WeatherAlert>[];

    if (weather.weatherCode >= 95) {
      alerts.add(_generatedAlert(
        id: 'storm_${lat}_${lon}_${weather.time}',
        title: 'Thunderstorm Advisory',
        event: 'Thunderstorm',
        description:
            'Thunderstorm conditions are active in $location. Seek shelter indoors and avoid open areas.',
        severity: 'severe',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 6)),
        lat: lat,
        lon: lon,
      ),);
    }

    if (weather.precipitation > 5 || weather.weatherCode >= 80) {
      alerts.add(_generatedAlert(
        id: 'rain_${lat}_${lon}_${weather.time}',
        title: 'Rainfall Advisory',
        event: 'Heavy Rain',
        description:
            'Rain is expected around $location. Keep an umbrella ready and watch for flooding in low-lying areas.',
        severity: 'moderate',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 8)),
        lat: lat,
        lon: lon,
      ),);
    }

    if (weather.temperature2m >= 33 || weather.apparentTemperature >= 36) {
      alerts.add(_generatedAlert(
        id: 'heat_${lat}_${lon}_${weather.time}',
        title: 'Heat Advisory',
        event: 'High Temperature',
        description:
            'Temperatures are elevated in $location. Stay hydrated, minimize direct sun exposure, and take frequent breaks.',
        severity: 'moderate',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 8)),
        lat: lat,
        lon: lon,
      ),);
    }

    if (weather.windSpeed10m >= 40) {
      alerts.add(_generatedAlert(
        id: 'wind_${lat}_${lon}_${weather.time}',
        title: 'Wind Advisory',
        event: 'Strong Winds',
        description:
            'Strong winds are possible in $location. Secure loose objects and avoid exposed areas.',
        severity: 'moderate',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 6)),
        lat: lat,
        lon: lon,
      ),);
    }

    return alerts;
  }

  WeatherAlert _generatedAlert({
    required String id,
    required String title,
    required String event,
    required String description,
    required String severity,
    required DateTime startsAt,
    required DateTime endsAt,
    required double lat,
    required double lon,
  }) {
    return WeatherAlert(
      id: id,
      title: title,
      description: description,
      severity: severity,
      event: event,
      startsAt: startsAt,
      endsAt: endsAt,
      isRead: false,
      lat: lat,
      lon: lon,
    );
  }

  Widget _buildHeader({
    required int unreadCount,
    required String cityName,
    required String countryCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 51),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.alertRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Alerts',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  countryCode.isNotEmpty ? '$cityName, $countryCode' : cityName,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$unreadCount',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.tempYellow,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'unread',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildInfoCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(
                Icons.verified_outlined,
                color: AppColors.white60,
                size: 36,
              ),
              SizedBox(height: 10),
              Text(
                'No active alerts right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pull to refresh after changing locations or weather updates.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparednessPanel({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildInfoCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.white60, size: 46),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SimpleChecklist(items: items),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white10),
      ),
      child: child,
    );
  }
}

class _WeatherSnapshot {
  final CurrentOpenMeteo? current;
  final String cityName;
  final String countryCode;
  final double lat;
  final double lon;

  const _WeatherSnapshot({
    required this.current,
    required this.cityName,
    required this.countryCode,
    required this.lat,
    required this.lon,
  });
}

class _AlertCard extends StatelessWidget {
  final WeatherAlert alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = WeatherUtils.getAlertSeverityColor(alert.severity);
    final icon = WeatherUtils.getAlertSeverityIcon(alert.severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: alert.isRead
                ? AppColors.white.withValues(alpha: 26)
                : color.withValues(alpha: 20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert.isRead
                  ? AppColors.white.withValues(alpha: 26)
                  : color.withValues(alpha: 102),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: alert.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tempYellow.withValues(alpha: 38),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: AppColors.tempYellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.event,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: AppColors.white.withValues(alpha: 204),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(
                          label: alert.severity.toUpperCase(),
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: alert.isRead ? 'READ' : 'UNREAD',
                          color: alert.isRead
                              ? AppColors.white60
                              : AppColors.tempYellow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 102)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SimpleChecklist extends StatelessWidget {
  final List<String> items;

  const _SimpleChecklist({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white.withValues(alpha: 210),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: AppColors.white.withValues(alpha: 200),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  final String label;
  final String number;

  const _HotlineRow({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, color: AppColors.white60, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white.withValues(alpha: 210),
              ),
            ),
          ),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              color: AppColors.white.withValues(alpha: 170),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded,
              color: AppColors.white60, size: 16,),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.white.withValues(alpha: 200)),
            ),
          ),
        ],
      ),
    );
  }
}
