import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_widgets.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather-based reminders
              if (provider.contextReminders.isNotEmpty) ...[
                const _SectionHeader(
                  icon: Icons.notifications_active_rounded,
                  title: "Today's Reminders",
                ),
                const SizedBox(height: 10),
                ...provider.contextReminders
                    .map((r) => ReminderCard(reminder: r)),
                const SizedBox(height: 20),
              ],

              // Typhoon Preparedness
              const _SectionHeader(
                icon: Icons.cyclone_rounded,
                title: 'Typhoon Preparedness',
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 10),
              const _PrepChecklist(
                items: [
                  'Charge all devices and power banks',
                  'Prepare emergency go-bag',
                  'Stock food and clean water (3-day supply)',
                  'Know your evacuation route',
                  'Keep important documents in waterproof bag',
                  'Check on elderly neighbors and relatives',
                ],
              ),
              const SizedBox(height: 20),

              // Emergency Hotlines
              const _SectionHeader(
                icon: Icons.phone_in_talk_rounded,
                title: 'Emergency Hotlines',
                color: Color(0xFF1565C0),
              ),
              const SizedBox(height: 10),
              const _HotlineCard(
                hotlines: [
                  {'label': 'Disaster Risk Reduction', 'number': '8-BAGYO'},
                  {'label': 'Ambulance (Red Cross)', 'number': '143'},
                  {'label': 'Police', 'number': '117'},
                  {'label': 'Fire Department', 'number': '(02) 8426-0219'},
                ],
              ),
              const SizedBox(height: 20),

              // Evacuation Tips
              const _SectionHeader(
                icon: Icons.directions_run_rounded,
                title: 'Evacuation Tips',
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              const _EvacuationCard(
                tips: [
                  'Stay calm, follow alerts and proceed to the nearest evacuation center',
                  'Bring your emergency kit and important documents',
                  'Assist children, elderly, and pets during evacuation',
                  'Do not return home until authorities declare it safe',
                ],
              ),
              const SizedBox(height: 20),

              // Power Outage Kit
              const _SectionHeader(
                icon: Icons.power_off_rounded,
                title: 'Power Outage Kit',
                color: Color(0xFFE65100),
              ),
              const SizedBox(height: 10),
              _PowerOutageKit(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PrepChecklist extends StatefulWidget {
  final List<String> items;

  const _PrepChecklist({required this.items});

  @override
  State<_PrepChecklist> createState() => _PrepChecklistState();
}

class _PrepChecklistState extends State<_PrepChecklist> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AtmosTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: widget.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return InkWell(
            onTap: () => setState(() => _checked[i] = !_checked[i]),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _checked[i]
                          ? AtmosTheme.primaryBlue
                          : Colors.transparent,
                      border: Border.all(
                        color: _checked[i]
                            ? AtmosTheme.primaryBlue
                            : const Color.fromARGB(255, 0, 0, 0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _checked[i]
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 15)

                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: _checked[i]
                            ? AtmosTheme.textLight
                            : AtmosTheme.textPrimary,
                        fontSize: 13,
                        decoration:
                            _checked[i] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HotlineCard extends StatelessWidget {
  final List<Map<String, String>> hotlines;

  const _HotlineCard({required this.hotlines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AtmosTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: hotlines.asMap().entries.map((entry) {
          final hotline = entry.value;
          final isLast = entry.key == hotlines.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: !isLast
                  ? const Border(
                      bottom: BorderSide(color: AtmosTheme.divider, width: 1))
                  : null,
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AtmosTheme.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_rounded,
                    color: AtmosTheme.primaryBlue, size: 16),
              ),
              title: Text(
                hotline['label'] ?? '',
                style: const TextStyle(
                  color: AtmosTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                hotline['number'] ?? '',
                style: const TextStyle(
                  color: AtmosTheme.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final number = hotline['number']?.replaceAll('-', '') ?? '';
                final uri = Uri.parse('tel:$number');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EvacuationCard extends StatelessWidget {
  final List<String> tips;

  const _EvacuationCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF43A047), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: AtmosTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PowerOutageKit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': '🔋', 'label': 'Batteries'},
      {'icon': '🔦', 'label': 'Flashlight'},
      {'icon': '📻', 'label': 'Portable Radio'},
      {'icon': '🔌', 'label': 'Powerbank'},
      {'icon': '💊', 'label': 'First Aid'},
      {'icon': '🕯️', 'label': 'Candles'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          return Container(
            width: (MediaQuery.of(context).size.width - 88) / 3,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['icon']!, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(
                  item['label']!,
                  style: const TextStyle(
                    color: AtmosTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
