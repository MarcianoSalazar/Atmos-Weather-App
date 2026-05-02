import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../widgets/weather_widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final country = provider.currentWeather?.country ?? '';

        // ✅ Filter alerts by country (fallback to all alerts when country unknown)
        final alerts = country.isNotEmpty
          ? provider.alerts
            .where((a) => a.location.toLowerCase().contains(country.toLowerCase()))
            .toList()
          : provider.alerts;

        

        // ✅ Loading state
        if (provider.status == WeatherStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 ACTIVE ALERT COUNT
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                            '${alerts.length} Active Alerts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            country.isNotEmpty
                                ? 'In $country'
                                : 'Near You',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🚨 ALERT LIST
                const Text(
                  'Active Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                if (alerts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No active weather alerts for this country.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...alerts.map((alert) => AlertCard(alert: alert)),

                const SizedBox(height: 20),

                // 📌 DISASTER PREPAREDNESS / REMINDERS
                const Text(
                  'Reminders & Preparedness',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // If there's a typhoon alert, show go-bag checklist
                if (alerts.any((a) => a.severity == AlertSeverity.typhoon))
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        // Go-bag image substitute
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withAlpha(26),
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
                              _SimpleChecklist(items: [
                                'Drinking water (3 days)',
                                'Non-perishable food',
                                'First aid kit & medicines',
                                'Flashlight & spare batteries',
                                'Portable radio / powerbank',
                                'Important documents in a waterproof bag',
                                'Extra clothing & sturdy shoes',
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // High heat reminders
                if ((provider.currentWeather?.temperature ?? 0) >= 30)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                        _SimpleChecklist(items: [
                          'Carry water & stay hydrated',
                          'Wear sunscreen & hat',
                          'Use a light umbrella for shade',
                        ]),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // ☎️ Emergency Hotlines
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      _HotlineRow(label: 'Disaster Hotline', number: 'Not available'),
                      _HotlineRow(label: 'Ambulance', number: 'Not available'),
                      _HotlineRow(label: 'Police', number: 'Not available'),
                      _HotlineRow(label: 'Fire Department', number: 'Not available'),
                    ],
                  ),
                ),

                // 🧭 Evacuation Tips
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Bullet(text: 'Stay calm, follow alerts and proceed to the nearest evacuation center.'),
                      _Bullet(text: 'Bring your emergency kit and important documents.'),
                      _Bullet(text: 'Assist children, elderly, and pets during evacuation.'),
                    ],
                  ),
                ),

                // 🔋 Power Outage Kit
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: _SimpleChecklist(items: [
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
          .map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.white.withAlpha(210), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
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
  const _HotlineRow({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withAlpha(210)),
            ),
          ),
          Text(
            number,
            style: TextStyle(color: Colors.white.withAlpha(170)),
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
              color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withAlpha(200)),
            ),
          ),
        ],
      ),
    );
  }
}