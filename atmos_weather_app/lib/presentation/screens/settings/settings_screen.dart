// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/settings_controller.dart';
import '../../../data/models/weather_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _settingsController = SettingsController.instance;

  AppSettings get _settings => _settingsController.settings;
  bool get _isLoading => !_settingsController.isLoaded;

  @override
  void initState() {
    super.initState();
    _settingsController.addListener(_handleSettingsUpdate);
    _settingsController.load();
  }

  @override
  void dispose() {
    _settingsController.removeListener(_handleSettingsUpdate);
    super.dispose();
  }

  void _handleSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _update(AppSettings updated) {
    _settingsController.update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryAccent))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                        child: _buildSection('UNITS', [
                      _buildDropdownTile(
                        icon: Icons.thermostat_rounded,
                        label: 'Temperature',
                        value: _settings.temperatureUnit,
                        options: const {
                          'celsius': '°C — Celsius',
                          'fahrenheit': '°F — Fahrenheit'
                        },
                        onChanged: (v) =>
                            _update(_settings.copyWith(temperatureUnit: v)),
                      ),
                      _buildDropdownTile(
                        icon: Icons.air_rounded,
                        label: 'Wind Speed',
                        value: _settings.windSpeedUnit,
                        options: const {
                          'kmh': 'km/h — Kilometers per hour',
                          'mph': 'mph — Miles per hour',
                          'ms': 'm/s — Meters per second',
                          'knots': 'kt — Knots',
                        },
                        onChanged: (v) =>
                            _update(_settings.copyWith(windSpeedUnit: v)),
                      ),
                      _buildDropdownTile(
                        icon: Icons.compress_rounded,
                        label: 'Pressure',
                        value: _settings.pressureUnit,
                        options: const {
                          'hpa': 'hPa — Hectopascal',
                          'inhg': 'inHg — Inches of Mercury',
                          'mmhg': 'mmHg — Millimeters of Mercury',
                        },
                        onChanged: (v) =>
                            _update(_settings.copyWith(pressureUnit: v)),
                      ),
                      _buildDropdownTile(
                        icon: Icons.visibility_rounded,
                        label: 'Visibility',
                        value: _settings.visibilityUnit,
                        options: const {
                          'km': 'km — Kilometers',
                          'mi': 'mi — Miles',
                        },
                        onChanged: (v) =>
                            _update(_settings.copyWith(visibilityUnit: v)),
                      ),
                    ])),
                    SliverToBoxAdapter(
                        child: _buildSection('DISPLAY', [
                      _buildSwitchTile(
                        icon: Icons.access_time_rounded,
                        label: '24-Hour Format',
                        subtitle: 'Display time in 24-hour format',
                        value: _settings.use24HourFormat,
                        onChanged: (v) =>
                            _update(_settings.copyWith(use24HourFormat: v)),
                      ),
                      _buildSwitchTile(
                        icon: Icons.masks_rounded,
                        label: 'Show Air Quality',
                        subtitle: 'Display AQI on home screen',
                        value: _settings.showAQI,
                        onChanged: (v) =>
                            _update(_settings.copyWith(showAQI: v)),
                      ),
                      _buildSwitchTile(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Show UV Index',
                        subtitle: 'Display UV index on home screen',
                        value: _settings.showUVIndex,
                        onChanged: (v) =>
                            _update(_settings.copyWith(showUVIndex: v)),
                      ),
                      _buildDropdownTile(
                        icon: Icons.map_rounded,
                        label: 'Map Style',
                        value: _settings.mapStyle,
                        options: const {
                          'dark': 'Dark — Dark themed map',
                          'light': 'Light — Light themed map',
                          'satellite': 'Satellite — Satellite view',
                        },
                        onChanged: (v) =>
                            _update(_settings.copyWith(mapStyle: v)),
                      ),
                    ])),
                    SliverToBoxAdapter(
                        child: _buildSection('NOTIFICATIONS', [
                      _buildSwitchTile(
                        icon: Icons.notifications_rounded,
                        label: 'Enable Notifications',
                        subtitle: 'Receive weather notifications',
                        value: _settings.notifications,
                        onChanged: (v) =>
                            _update(_settings.copyWith(notifications: v)),
                      ),
                      _buildSwitchTile(
                        icon: Icons.warning_amber_rounded,
                        label: 'Severe Alerts',
                        subtitle: 'Notify on severe weather events',
                        value: _settings.severeAlertNotifications,
                        enabled: _settings.notifications,
                        onChanged: (v) => _update(
                            _settings.copyWith(severeAlertNotifications: v)),
                      ),
                      _buildSwitchTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Precipitation Alerts',
                        subtitle: 'Notify when rain is expected',
                        value: _settings.precipitationNotifications,
                        enabled: _settings.notifications,
                        onChanged: (v) => _update(
                            _settings.copyWith(precipitationNotifications: v)),
                      ),
                      _buildSwitchTile(
                        icon: Icons.wb_twilight_rounded,
                        label: 'Daily Summary',
                        subtitle: 'Morning weather briefing',
                        value: _settings.dailySummaryNotifications,
                        enabled: _settings.notifications,
                        onChanged: (v) => _update(
                            _settings.copyWith(dailySummaryNotifications: v)),
                      ),
                    ])),
                    SliverToBoxAdapter(
                        child: _buildSection('API CONFIGURATION', [
                      _buildApiInfoTile(
                        icon: Icons.cloud_rounded,
                        label: 'Open-Meteo',
                        subtitle: 'Weather & Air Quality (Free, Active)',
                        isActive: true,
                      ),
                      _buildApiInfoTile(
                        icon: Icons.public_rounded,
                        label: 'Geoapify',
                        subtitle: AppConstants.geoapifyApiKey ==
                                'YOUR_GEOAPIFY_API_KEY'
                            ? 'Not configured — Add API key in constants'
                            : 'Active — Place search & reverse geocode',
                        isActive: AppConstants.geoapifyApiKey !=
                            'YOUR_GEOAPIFY_API_KEY',
                      ),
                      _buildApiInfoTile(
                        icon: Icons.cloud_queue_rounded,
                        label: 'OpenWeatherMap',
                        subtitle: AppConstants.openWeatherApiKey ==
                                'YOUR_OPENWEATHERMAP_API_KEY'
                            ? 'Not configured — Add API key in constants'
                            : 'Active — Map tiles & extended data',
                        isActive: AppConstants.openWeatherApiKey !=
                            'YOUR_OPENWEATHERMAP_API_KEY',
                      ),
                      _buildApiInfoTile(
                        icon: Icons.map_rounded,
                        label: 'Map Tiles',
                        subtitle: 'CartoDB Dark (Free, Active)',
                        isActive: true,
                      ),
                    ])),
                    SliverToBoxAdapter(
                        child: _buildSection('ABOUT', [
                      _buildInfoTile(
                        icon: Icons.info_outline_rounded,
                        label: 'App Version',
                        value: AppConstants.appVersion,
                      ),
                      _buildInfoTile(
                        icon: Icons.cloud_done_rounded,
                        label: 'Data Sources',
                        value: 'Open-Meteo, OWM',
                      ),
                      _buildActionTile(
                        icon: Icons.delete_sweep_rounded,
                        label: 'Clear Cache',
                        color: AppColors.alertOrange,
                        onTap: _clearCache,
                      ),
                      _buildActionTile(
                        icon: Icons.restore_rounded,
                        label: 'Reset to Defaults',
                        color: AppColors.alertRed,
                        onTap: _resetSettings,
                      ),
                    ])),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white60,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white10,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white10),
            ),
            child: Column(
              children: children
                  .asMap()
                  .entries
                  .map((e) => Column(children: [
                        e.value,
                        if (e.key < children.length - 1)
                          const Divider(
                              height: 1, color: AppColors.white10, indent: 52),
                      ]))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withAlpha(38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryAccent, size: 18),
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
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            color: AppColors.white60,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String label,
    required String value,
    required Map<String, String> options,
    required void Function(String) onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.tempYellow.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.tempYellow, size: 18),
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
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.white40, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showOptionsSheet(label, value, options, onChanged),
    );
  }

  Widget _buildApiInfoTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isActive,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isActive ? AppColors.accentGreen : AppColors.white40)
              .withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isActive ? AppColors.accentGreen : AppColors.white40,
            size: 18),
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
          color: isActive ? AppColors.accentGreen : AppColors.white40,
        ),
      ),
      trailing: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : AppColors.white40,
          shape: BoxShape.circle,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.white60, size: 18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
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
      trailing: Icon(Icons.chevron_right_rounded,
          color: color.withAlpha(153), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  void _showOptionsSheet(
    String title,
    String currentValue,
    Map<String, String> options,
    void Function(String) onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
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
            final isSelected = e.key == currentValue;
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
    showDialog<void>(
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
              fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will remove all cached weather data. Fresh data will be fetched on next load.',
          style: TextStyle(
              fontFamily: 'Rajdhani', color: AppColors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Rajdhani', color: AppColors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertOrange),
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.currentWeatherCache);
              await prefs.remove('${AppConstants.currentWeatherCache}_time');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
            child: const Text('Clear',
                style:
                    TextStyle(fontFamily: 'Rajdhani', color: AppColors.white)),
          ),
        ],
      ),
    );
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
              fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'All settings will be restored to their default values.',
          style: TextStyle(
              fontFamily: 'Rajdhani', color: AppColors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Rajdhani', color: AppColors.white60)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () {
              Navigator.pop(ctx);
              _update(AppSettings());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset',
                style:
                    TextStyle(fontFamily: 'Rajdhani', color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
