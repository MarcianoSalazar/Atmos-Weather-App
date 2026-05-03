// lib/presentation/screens/alerts/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../bloc/weather/weather_bloc.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with AutomaticKeepAliveClientMixin<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loadingAlerts = false;
  double? _cachedLat;
  double? _cachedLon;
  String _cachedCountry = '';
  double? _cachedTemp;

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchAlerts(double lat, double lon) async {
    if (_loadingAlerts) return;
    setState(() => _loadingAlerts = true);
    try {
      final repo = context.read<WeatherRepository>();
      final data = await repo.fetchOpenWeatherMap(lat: lat, lon: lon);
      if (mounted) {
        setState(() {
          _alerts = ((data?['alerts'] as List<dynamic>?) ?? [])
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _alerts = []);
    } finally {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: SafeArea(
          child: BlocConsumer<WeatherBloc, WeatherState>(
            listener: (context, state) {
              if (state is WeatherLoaded) {
                // Fetch alerts when location changes
                if (state.lat != _cachedLat || state.lon != _cachedLon) {
                  _cachedLat = state.lat;
                  _cachedLon = state.lon;
                  _cachedCountry = state.countryCode;
                  _cachedTemp = state.weather.current?.temperature2m;
                  _fetchAlerts(state.lat, state.lon);
                }
              }
            },
            builder: (context, state) {
              final isLoading =
                  state is WeatherLoading || state is WeatherInitial;

              if (isLoading && _cachedLat == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WeatherBloc>().add(const RefreshWeather());
                  if (_cachedLat != null && _cachedLon != null) {
                    await _fetchAlerts(_cachedLat!, _cachedLon!);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Active alert count ──────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _loadingAlerts
                                      ? 'Loading alerts…'
                                      : '${_alerts.length} Active Alerts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _cachedCountry.isNotEmpty
                                      ? 'In $_cachedCountry'
                                      : 'Near You',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Alert list ──────────────────────────────────────
                      const Text(
                        'Active Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_loadingAlerts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_alerts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _cachedLat == null
                                ? 'Search for a location to see weather alerts.'
                                : 'No active weather alerts for this location.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._alerts.map((a) => _AlertCard(alert: a)),

                      const SizedBox(height: 20),

                      // ── Disaster Preparedness ───────────────────────────
                      const Text(
                        'Reminders & Preparedness',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Go-bag checklist shown when typhoon/storm alerts present
                      if (_hasTyphoonAlert())
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.backpack_rounded,
                                      color: Colors.white70, size: 48),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Go-Bag Checklist',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _SimpleChecklist(items: const [
                                      'Drinking water (3 days)',
                                      'Non-perishable food',
                                      'First aid kit & medicines',
                                      'Flashlight & spare batteries',
                                      'Portable radio / powerbank',
                                      'Important documents in waterproof bag',
                                      'Extra clothing & sturdy shoes',
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Heat reminders
                      if ((_cachedTemp ?? 0) >= 30)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Heat Index Reminders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SimpleChecklist(items: const [
                                'Carry water & stay hydrated',
                                'Wear sunscreen & hat',
                                'Use a light umbrella for shade',
                              ]),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // ── Emergency Hotlines ──────────────────────────────
                      const Text(
                        'Emergency Hotlines',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: const Column(
                          children: [
                            _HotlineRow(
                                label: 'Disaster Hotline',
                                number: 'Not available'),
                            _HotlineRow(
                                label: 'Ambulance', number: 'Not available'),
                            _HotlineRow(
                                label: 'Police', number: 'Not available'),
                            _HotlineRow(
                                label: 'Fire Department',
                                number: 'Not available'),
                          ],
                        ),
                      ),

                      // ── Evacuation Tips ─────────────────────────────────
                      const Text(
                        'Evacuation Tips',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bullet(
                                text:
                                    'Stay calm, follow alerts and proceed to the nearest evacuation center.'),
                            _Bullet(
                                text:
                                    'Bring your emergency kit and important documents.'),
                            _Bullet(
                                text:
                                    'Assist children, elderly, and pets during evacuation.'),
                          ],
                        ),
                      ),

                      // ── Power Outage Kit ────────────────────────────────
                      const Text(
                        'Power Outage Kit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: _SimpleChecklist(items: const [
                          'Batteries & flashlight',
                          'Candles & lighter',
                          'Portable radio',
                          'Powerbank & charging cables',
                          'Spare cash',
                        ]),
                      ),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Weather alerts are location-based. Data updates automatically when you search for a new city.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _hasTyphoonAlert() {
    return _alerts.any((a) {
      final event = (a['event'] as String? ?? '').toLowerCase();
      return event.contains('typhoon') ||
          event.contains('tropical') ||
          event.contains('storm');
    });
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final event = alert['event'] as String? ?? 'Weather Alert';
    final description = alert['description'] as String? ?? '';
    final senderName = alert['sender_name'] as String? ?? '';
    final startMs =
        ((alert['start'] as num?)?.toInt() ?? 0) * 1000;
    final startTime = startMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(startMs)
        : null;

    final eventLower = event.toLowerCase();
    late final Color color;
    late final IconData icon;
    late final String label;

    if (eventLower.contains('typhoon') ||
        eventLower.contains('tropical') ||
        eventLower.contains('storm')) {
      color = const Color(0xFFB71C1C);
      icon = Icons.cyclone_rounded;
      label = 'TYPHOON';
    } else if (eventLower.contains('warning') ||
        eventLower.contains('watch')) {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
      label = 'WARNING';
    } else if (eventLower.contains('advisory')) {
      color = Colors.amber;
      icon = Icons.info_rounded;
      label = 'ADVISORY';
    } else {
      color = Colors.blueAccent;
      icon = Icons.notifications_rounded;
      label = 'ALERT';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
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
                color: color.withValues(alpha: 0.1),
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
                      if (senderName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            senderName,
                            style: const TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (startTime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Since ${startTime.month}/${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SimpleChecklist extends StatelessWidget {
  final List<String> items;
  const _SimpleChecklist({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.white.withValues(alpha: 0.82), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  final String label;
  final String number;
  const _HotlineRow({super.key, required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
          ),
          Text(
            number,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.67)),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded,
              color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
            ),
          ),
        ],
      ),
    );
  }
}
