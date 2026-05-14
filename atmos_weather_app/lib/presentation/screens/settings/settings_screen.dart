// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atmos/core/constants/app_constants.dart';
import 'package:atmos/core/theme/app_theme.dart';
import 'package:atmos/data/models/weather_model.dart';
import 'package:atmos/core/utils/settings_controller.dart';

// Singleton notifications plugin
final FlutterLocalNotificationsPlugin _notifPlugin =
    FlutterLocalNotificationsPlugin();
bool _notifInitialized = false;

Future<void> _initNotifications() async {
  if (_notifInitialized) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
  );
  await _notifPlugin.initialize(initSettings);
  _notifInitialized = true;
}

Future<bool> _requestNotificationPermission() async {
  final android = _notifPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final ios = _notifPlugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();

  if (android != null) {
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }
  if (ios != null) {
    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }
  return true;
}

Future<void> _sendTestNotification(String title, String body) async {
  await _initNotifications();
  const androidDetails = AndroidNotificationDetails(
    'atmos_weather',
    'ATMOS Weather Alerts',
    channelDescription: 'Weather alerts and notifications from ATMOS',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF2196F3),
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  await _notifPlugin.show(0, title, body, details);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  final SettingsController _settingsController = SettingsController.instance;

  @override
  void initState() {
    super.initState();
    _settingsController.addListener(_onSettingsChanged);
    _loadSettings();
    _initNotifications();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() => _settings = _settingsController.settings);
  }

  Future<void> _loadSettings() async {
    await _settingsController.load();
    _settings = _settingsController.settings;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _update(AppSettings updated) async {
    setState(() => _settings = updated);
    await _settingsController.update(updated);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  // ─── Toggle notifications with real permission request ────────────────────
  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      await _initNotifications();
      final granted = await _requestNotificationPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission denied. Enable in device settings.',
              ),
              backgroundColor: AppColors.alertRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await _update(_settings.copyWith(notifications: true));
      // Send a welcome test notification
      await _sendTestNotification(
        '🌤️ ATMOS Notifications Active',
        'You will now receive weather alerts and updates.',
      );
    } else {
      await _update(
        _settings.copyWith(
          notifications: false,
          severeAlertNotifications: false,
          dailySummaryNotifications: false,
          precipitationNotifications: false,
        ),
      );
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
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryAccent),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: _buildSection('UNITS', [
                        _dropdownTile(
                          icon: Icons.thermostat_rounded,
                          iconColor: AppColors.tempOrange,
                          label: 'Temperature',
                          value: _settings.temperatureUnit,
                          options: const {
                            'celsius': '°C — Celsius',
                            'fahrenheit': '°F — Fahrenheit',
                          },
                          onChanged: (v) =>
                              _update(_settings.copyWith(temperatureUnit: v)),
                        ),
                        _dropdownTile(
                          icon: Icons.air_rounded,
                          iconColor: AppColors.primaryBright,
                          label: 'Wind Speed',
                          value: _settings.windSpeedUnit,
                          options: const {
                            'kmh': 'km/h',
                            'mph': 'mph',
                            'ms': 'm/s',
                            'knots': 'Knots',
                          },
                          onChanged: (v) =>
                              _update(_settings.copyWith(windSpeedUnit: v)),
                        ),
                        _dropdownTile(
                          icon: Icons.compress_rounded,
                          iconColor: const Color(0xFF4FC3F7),
                          label: 'Pressure',
                          value: _settings.pressureUnit,
                          options: const {
                            'hpa': 'hPa',
                            'inhg': 'inHg',
                            'mmhg': 'mmHg',
                          },
                          onChanged: (v) =>
                              _update(_settings.copyWith(pressureUnit: v)),
                        ),
                        _dropdownTile(
                          icon: Icons.visibility_rounded,
                          iconColor: AppColors.primaryGlow,
                          label: 'Visibility',
                          value: _settings.visibilityUnit,
                          options: const {'km': 'km', 'mi': 'Miles'},
                          onChanged: (v) =>
                              _update(_settings.copyWith(visibilityUnit: v)),
                        ),
                      ]),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSection('DISPLAY', [
                        _switchTile(
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.primaryAccent,
                          label: '24-Hour Format',
                          subtitle: 'Use 24-hour time display',
                          value: _settings.use24HourFormat,
                          onChanged: (v) =>
                              _update(_settings.copyWith(use24HourFormat: v)),
                        ),
                        _switchTile(
                          icon: Icons.masks_rounded,
                          iconColor: const Color(0xFF66BB6A),
                          label: 'Show Air Quality',
                          subtitle: 'Display AQI on home screen',
                          value: _settings.showAQI,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showAQI: v)),
                        ),
                        _switchTile(
                          icon: Icons.wb_sunny_rounded,
                          iconColor: AppColors.tempYellow,
                          label: 'Show UV Index',
                          subtitle: 'Display UV index data',
                          value: _settings.showUVIndex,
                          onChanged: (v) =>
                              _update(_settings.copyWith(showUVIndex: v)),
                        ),
                        _dropdownTile(
                          icon: Icons.map_rounded,
                          iconColor: const Color(0xFF4DB6AC),
                          label: 'Map Style',
                          value: _settings.mapStyle,
                          options: const {
                            'dark': 'Dark',
                            'light': 'Light',
                            'satellite': 'Satellite',
                          },
                          onChanged: (v) =>
                              _update(_settings.copyWith(mapStyle: v)),
                        ),
                      ]),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSection('NOTIFICATIONS', [
                        _switchTile(
                          icon: Icons.notifications_rounded,
                          iconColor: AppColors.primaryAccent,
                          label: 'Enable Notifications',
                          subtitle: 'Receive weather alerts & updates',
                          value: _settings.notifications,
                          onChanged: _toggleNotifications,
                        ),
                        _switchTile(
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.alertRed,
                          label: 'Severe Alerts',
                          subtitle: 'Notify on severe weather events',
                          value: _settings.severeAlertNotifications,
                          enabled: _settings.notifications,
                          onChanged: (v) async {
                            await _update(
                              _settings.copyWith(
                                severeAlertNotifications: v,
                              ),
                            );
                            if (v) {
                              await _sendTestNotification(
                                '⚠️ Severe Alert Notifications On',
                                'You will be notified of severe weather events.',
                              );
                            }
                          },
                        ),
                        _switchTile(
                          icon: Icons.water_drop_rounded,
                          iconColor: AppColors.primaryBright,
                          label: 'Precipitation Alerts',
                          subtitle: 'Notify when rain is expected',
                          value: _settings.precipitationNotifications,
                          enabled: _settings.notifications,
                          onChanged: (v) async {
                            await _update(
                              _settings.copyWith(
                                precipitationNotifications: v,
                              ),
                            );
                            if (v) {
                              await _sendTestNotification(
                                '🌧️ Precipitation Alerts On',
                                'You will be notified before rain arrives.',
                              );
                            }
                          },
                        ),
                        _switchTile(
                          icon: Icons.wb_twilight_rounded,
                          iconColor: AppColors.tempYellowWarm,
                          label: 'Daily Summary',
                          subtitle: 'Morning weather briefing',
                          value: _settings.dailySummaryNotifications,
                          enabled: _settings.notifications,
                          onChanged: (v) async {
                            await _update(
                              _settings.copyWith(
                                dailySummaryNotifications: v,
                              ),
                            );
                            if (v) {
                              await _sendTestNotification(
                                '🌤️ Daily Summary On',
                                'You will receive a morning weather briefing.',
                              );
                            }
                          },
                        ),
                      ]),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSection('API CONFIGURATION', [
                        _apiTile(
                          icon: Icons.cloud_rounded,
                          label: 'Open-Meteo',
                          subtitle: 'Weather & Air Quality (Free, Active)',
                          isActive: true,
                        ),
                        _apiTile(
                          icon: Icons.public_rounded,
                          label: 'Geoapify',
                          subtitle: AppConstants.geoapifyApiKey ==
                                  'YOUR_GEOAPIFY_API_KEY'
                              ? 'Not configured'
                              : 'Active — Place search & reverse geocode',
                          isActive: AppConstants.geoapifyApiKey !=
                              'YOUR_GEOAPIFY_API_KEY',
                        ),
                        _apiTile(
                          icon: Icons.cloud_queue_rounded,
                          label: 'OpenWeatherMap',
                          subtitle: AppConstants.openWeatherApiKey ==
                                  'YOUR_OPENWEATHERMAP_API_KEY'
                              ? 'Not configured'
                              : 'Active — Map tiles & extended data',
                          isActive: AppConstants.openWeatherApiKey !=
                              'YOUR_OPENWEATHERMAP_API_KEY',
                        ),
                        _apiTile(
                          icon: Icons.map_rounded,
                          label: 'Map Tiles',
                          subtitle: 'CartoDB Dark (Free, Active)',
                          isActive: true,
                        ),
                      ]),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSection('ABOUT', [
                        _infoTile(
                          icon: Icons.info_outline_rounded,
                          label: 'App Version',
                          value: AppConstants.appVersion,
                        ),
                        _infoTile(
                          icon: Icons.cloud_done_rounded,
                          label: 'Data Sources',
                          value: 'Open-Meteo, Geoapify, OWM',
                        ),
                        _actionTile(
                          icon: Icons.delete_sweep_rounded,
                          label: 'Clear Cache',
                          color: AppColors.alertOrange,
                          onTap: _clearCache,
                        ),
                        _actionTile(
                          icon: Icons.restore_rounded,
                          label: 'Reset to Defaults',
                          color: AppColors.alertRed,
                          onTap: _resetSettings,
                        ),
                      ]),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Customize your experience',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppColors.white60,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white20),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section container ─────────────────────────────────────────────────────
  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                // HIGH CONTRAST — bright white, not white60
                color: AppColors.white80,
                letterSpacing: 1.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              // Slightly lighter surface for better contrast
              color: const Color(0xFF0F2540),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Column(
              children: children.asMap().entries.map((e) {
                return Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(
                        height: 1,
                        color: Color(0xFF1E3A5F),
                        indent: 52,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Switch tile ───────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(46),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withAlpha(77)),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.white, // FULL white for contrast
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            color: AppColors.white60,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.tempYellow,
          activeTrackColor: AppColors.primaryAccent,
          inactiveThumbColor: const Color(0xFF8899BB),
          inactiveTrackColor: const Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  // ─── Dropdown tile ─────────────────────────────────────────────────────────
  Widget _dropdownTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Map<String, String> options,
    required void Function(String) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(46),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withAlpha(77)),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      subtitle: Text(
        options[value] ?? value,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 12,
          color: AppColors.white60,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.white60,
        size: 20,
      ),
      onTap: () => _showPicker(label, value, options, onChanged),
    );
  }

  // ─── API tile ──────────────────────────────────────────────────────────────
  Widget _apiTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isActive,
  }) {
    final color = isActive ? AppColors.accentGreen : const Color(0xFF8899BB);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 12,
          color: isActive ? AppColors.accentGreen : const Color(0xFF8899BB),
        ),
      ),
      trailing: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : const Color(0xFF8899BB),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─── Info tile ─────────────────────────────────────────────────────────────
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white20),
        ),
        child: Icon(icon, color: AppColors.white60, size: 19),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          color: AppColors.white60,
        ),
      ),
    );
  }

  // ─── Action tile ───────────────────────────────────────────────────────────
  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withAlpha(153),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  // ─── Option picker sheet ───────────────────────────────────────────────────
  void _showPicker(
    String title,
    String current,
    Map<String, String> options,
    void Function(String) onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white20,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const Divider(color: AppColors.white10),
          ...options.entries.map((e) {
            final isSelected = e.key == current;
            return ListTile(
              title: Text(
                e.value,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.tempYellow : AppColors.white,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: AppColors.tempYellow)
                  : null,
              onTap: () {
                onChanged(e.key);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cache',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Cached weather data will be removed. Fresh data will be fetched.',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            color: AppColors.white60,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white60,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertOrange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.currentWeatherCache);
      await prefs.remove('${AppConstants.currentWeatherCache}_time');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetSettings() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Settings',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'All settings will be restored to defaults.',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            color: AppColors.white60,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white60,
              ),
            ),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () {
              Navigator.pop(ctx);
              _update(AppSettings());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
