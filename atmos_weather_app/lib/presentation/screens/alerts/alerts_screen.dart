// lib/presentation/screens/alerts/alerts_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:atmos/core/theme/app_theme.dart';
import 'package:atmos/core/utils/weather_utils.dart';
import 'package:atmos/data/models/weather_model.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/presentation/bloc/weather/weather_bloc.dart';

// ─── Country-based emergency hotlines ────────────────────────────────────────
const Map<String, List<_HotlineData>> _hotlinesByCountry = {
  'Philippines': [
    _HotlineData('NDRRMC / Emergency', '911'),
    _HotlineData('Philippine Red Cross', '143'),
    _HotlineData('PNP Police', '117'),
    _HotlineData('BFP Fire Dept.', '160'),
  ],
  'Japan': [
    _HotlineData('Police', '110'),
    _HotlineData('Fire / Ambulance', '119'),
    _HotlineData('Coast Guard', '118'),
    _HotlineData('Disaster Prevention', '171'),
  ],
  'United States': [
    _HotlineData('Emergency', '911'),
    _HotlineData('FEMA', '1-800-621-3362'),
    _HotlineData('Red Cross', '1-800-733-2767'),
    _HotlineData('Poison Control', '1-800-222-1222'),
  ],
  'United Kingdom': [
    _HotlineData('Emergency', '999'),
    _HotlineData('Non-emergency', '101'),
    _HotlineData('NHS', '111'),
  ],
  'Australia': [
    _HotlineData('Emergency', '000'),
    _HotlineData('SES', '132 500'),
    _HotlineData('Lifeline', '13 11 14'),
  ],
  'Singapore': [
    _HotlineData('Emergency', '999'),
    _HotlineData('Ambulance / SCDF', '995'),
    _HotlineData('Non-emergency', '1800-255-0000'),
  ],
  'India': [
    _HotlineData('Police', '100'),
    _HotlineData('Ambulance', '102'),
    _HotlineData('Fire', '101'),
    _HotlineData('Disaster Mgmt', '108'),
  ],
  'South Korea': [
    _HotlineData('Police', '112'),
    _HotlineData('Fire / Ambulance', '119'),
    _HotlineData('Coast Guard', '122'),
  ],
  'China': [
    _HotlineData('Police', '110'),
    _HotlineData('Fire', '119'),
    _HotlineData('Ambulance', '120'),
  ],
};

const List<_HotlineData> _defaultHotlines = [
  _HotlineData('Emergency', 'Check local listing'),
  _HotlineData('Ambulance', 'Check local listing'),
  _HotlineData('Police', 'Check local listing'),
  _HotlineData('Fire Department', 'Check local listing'),
];

class _HotlineData {
  final String label;
  final String number;
  const _HotlineData(this.label, this.number);
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<WeatherAlert> _alerts = [];
  bool _loadingAlerts = false;
  String? _alertError;
  String _lastFetchKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryFetch());
  }

  void _tryFetch() {
    final state = context.read<WeatherBloc>().state;
    if (state is WeatherLoaded) {
      _fetchAlerts(state.lat, state.lon, state.cityName, state.countryCode);
    }
  }

  Future<void> _fetchAlerts(
    double lat,
    double lon,
    String city,
    String country,
  ) async {
    final key = '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
    if (key == _lastFetchKey && _alerts.isNotEmpty) return;
    _lastFetchKey = key;

    if (!mounted) return;
    setState(() {
      _loadingAlerts = true;
      _alertError = null;
    });

    try {
      // Open-Meteo does not have a dedicated alert endpoint.
      // We derive smart, data-driven alerts from the free forecast API.
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
      final resp = await dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': [
            'temperature_2m',
            'weather_code',
            'wind_speed_10m',
            'precipitation',
            'surface_pressure',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_sum',
            'wind_speed_10m_max',
            'uv_index_max',
          ].join(','),
          'timezone': 'auto',
          'forecast_days': 3,
        },
      );

      final data = resp.data!;
      final cur = data['current'] as Map<String, dynamic>? ?? {};
      final daily = data['daily'] as Map<String, dynamic>? ?? {};

      final alerts = <WeatherAlert>[];
      final now = DateTime.now();

      // ── Derive alerts from current + 3-day data ──────────────────────────
      final temp = (cur['temperature_2m'] as num?)?.toDouble() ?? 0;
      final windSpeed = (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0;
      final precip = (cur['precipitation'] as num?)?.toDouble() ?? 0;
      final pressure = (cur['surface_pressure'] as num?)?.toDouble() ?? 1013;
      final wCode = (cur['weather_code'] as num?)?.toInt() ?? 0;

      final dailyMaxTemps = (daily['temperature_2m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0)
              .toList() ??
          [];
      final dailyPrecipSums = (daily['precipitation_sum'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0)
              .toList() ??
          [];
      final dailyWindMax = (daily['wind_speed_10m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0)
              .toList() ??
          [];
      final dailyUvMax = (daily['uv_index_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0)
              .toList() ??
          [];
      final dailyCodes = (daily['weather_code'] as List?)
              ?.map((e) => (e as num?)?.toInt() ?? 0)
              .toList() ??
          [];

      // Typhoon / tropical cyclone (codes 95-99 = thunderstorm / severe storm)
      final hasTyphoon = dailyCodes.any((c) => c >= 95) || wCode >= 95;
      if (hasTyphoon) {
        alerts.add(
          WeatherAlert(
            id: 'typhoon_$key',
            title: 'Severe Storm / Cyclone Warning',
            description: 'Severe storm conditions detected near $city. '
                'Wind speeds may exceed 80 km/h with heavy rainfall. '
                'Residents in coastal and low-lying areas should prepare go-bags '
                'and monitor official advisories closely.',
            severity: 'Extreme',
            event: 'Typhoon',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 36)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // Heavy rain
      final maxDailyPrecip = dailyPrecipSums.isNotEmpty
          ? dailyPrecipSums.reduce((a, b) => a > b ? a : b)
          : 0.0;
      if (maxDailyPrecip >= 50 || precip > 5) {
        alerts.add(
          WeatherAlert(
            id: 'heavyrain_$key',
            title: 'Heavy Rain Advisory',
            description: 'Heavy rainfall is expected over the next 24–48 hours '
                'with accumulations up to ${maxDailyPrecip.round()} mm possible near $city. '
                'Flash flooding of low-lying and poor-drainage areas is possible. '
                'Motorists should exercise caution.',
            severity: 'Moderate',
            event: 'Heavy Rain',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 24)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // Strong winds
      final maxWind = dailyWindMax.isNotEmpty
          ? dailyWindMax.reduce((a, b) => a > b ? a : b)
          : windSpeed;
      if (maxWind >= 50 || windSpeed >= 40) {
        alerts.add(
          WeatherAlert(
            id: 'wind_$key',
            title: 'Strong Wind Warning',
            description: 'Strong winds with sustained speeds of '
                '${windSpeed.round()}–${maxWind.round()} km/h are expected near $city. '
                'Secure loose outdoor items. Residents in exposed coastal areas '
                'should take precautionary measures.',
            severity: maxWind >= 80 ? 'Severe' : 'Moderate',
            event: 'Strong Wind',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 18)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // Extreme heat
      final maxTemp = dailyMaxTemps.isNotEmpty
          ? dailyMaxTemps.reduce((a, b) => a > b ? a : b)
          : temp;
      if (maxTemp >= 38 || temp >= 36) {
        alerts.add(
          WeatherAlert(
            id: 'heat_$key',
            title: 'Extreme Heat Advisory',
            description: 'Dangerous heat conditions expected near $city with '
                'temperatures reaching ${maxTemp.round()}°C. '
                'Heat index values may reach 41–54°C. '
                'Limit outdoor activities between 10 AM and 4 PM. '
                'Stay hydrated and seek air-conditioned environments.',
            severity: maxTemp >= 42 ? 'Extreme' : 'Severe',
            event: 'Extreme Heat',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 24)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      } else if (temp >= 30 && temp < 36) {
        alerts.add(
          WeatherAlert(
            id: 'hightemp_$key',
            title: 'Heat Index Advisory',
            description: 'High temperatures of ${temp.round()}°C near $city. '
                'Carry water, wear sunscreen, and use shade when possible.',
            severity: 'Minor',
            event: 'High Temperature',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 12)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // High UV
      final maxUv = dailyUvMax.isNotEmpty
          ? dailyUvMax.reduce((a, b) => a > b ? a : b)
          : 0.0;
      if (maxUv >= 8) {
        alerts.add(
          WeatherAlert(
            id: 'uv_$key',
            title: 'High UV Index Warning',
            description:
                'UV index is forecast to reach ${maxUv.round()} (${WeatherUtils.getUVLabel(maxUv)}) '
                'near $city. Use SPF 50+ sunscreen, UV-blocking sunglasses, '
                'and protective clothing. Avoid direct sun exposure midday.',
            severity: maxUv >= 11 ? 'Extreme' : 'Severe',
            event: 'High UV',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 10)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // Low pressure / storm system
      if (pressure < 990) {
        alerts.add(
          WeatherAlert(
            id: 'pressure_$key',
            title: 'Low Pressure System',
            description:
                'A low pressure system (${pressure.round()} hPa) is present '
                'near $city, indicating an active storm system. '
                'Expect unsettled weather with possible heavy rain and strong winds.',
            severity: 'Moderate',
            event: 'Low Pressure',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 24)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      // Fog / mist
      if (wCode == 45 || wCode == 48) {
        alerts.add(
          WeatherAlert(
            id: 'fog_$key',
            title: 'Dense Fog Advisory',
            description:
                'Dense fog is affecting $city with visibility below 200 m. '
                'Motorists should reduce speed, increase following distance, '
                'and use fog lights.',
            severity: 'Minor',
            event: 'Dense Fog',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 6)),
            isRead: false,
            lat: lat,
            lon: lon,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loadingAlerts = false;
        });
        await context.read<WeatherRepository>().saveAlerts(alerts);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertError = 'Failed to load alerts. Pull to refresh.';
          _loadingAlerts = false;
        });
      }
    }
  }

  void _markRead(String id) {
    setState(() {
      final idx = _alerts.indexWhere((a) => a.id == id);
      if (idx >= 0) _alerts[idx] = _alerts[idx].copyWith(isRead: true);
    });
    context.read<WeatherRepository>().markAlertRead(id);
  }

  void _markAllRead() {
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    });
    context.read<WeatherRepository>().saveAlerts(_alerts);
  }

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;
  bool get _hasTyphoon => _alerts.any((a) => a.event == 'Typhoon');

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeatherBloc, WeatherState>(
      listener: (context, state) {
        if (state is WeatherLoaded) {
          _fetchAlerts(state.lat, state.lon, state.cityName, state.countryCode);
        }
      },
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          final cityName =
              state is WeatherLoaded ? state.cityName : 'Your Area';
          final country = state is WeatherLoaded ? state.countryCode : '';
          final currentTemp = state is WeatherLoaded
              ? (state.weather.current?.temperature2m ?? 0.0)
              : 0.0;

          final hotlines = _hotlinesByCountry[country] ?? _defaultHotlines;

          return Scaffold(
            backgroundColor: AppColors.primaryDeep,
            body: Container(
              decoration: const BoxDecoration(gradient: AppColors.skyGradient),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (state is WeatherLoaded) {
                      await _fetchAlerts(
                        state.lat,
                        state.lon,
                        state.cityName,
                        state.countryCode,
                      );
                    }
                  },
                  color: AppColors.tempYellow,
                  backgroundColor: AppColors.primaryDark,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(cityName, country),
                      ),
                      SliverToBoxAdapter(
                        child: _buildAlertBanner(cityName, country),
                      ),
                      SliverToBoxAdapter(
                        child: _buildAlertsList(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildPreparednessSection(currentTemp),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHotlines(hotlines),
                      ),
                      SliverToBoxAdapter(
                        child: _buildEvacuationTips(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildPowerOutageKit(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildFooterNote(),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(String cityName, String country) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ALERTS',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 3,
                ),
              ),
              Text(
                country.isNotEmpty ? '$cityName, $country' : cityName,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppColors.white60,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_unreadCount > 0) ...[
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppColors.primaryBright,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Alert banner ────────────────────────────────────────────────────────
  Widget _buildAlertBanner(String cityName, String country) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loadingAlerts
                        ? 'Checking alerts…'
                        : '${_alerts.length} Active Alert${_alerts.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    country.isNotEmpty ? 'In $country' : 'Near You',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: AppColors.white.withAlpha(179),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.alertRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Alerts list ─────────────────────────────────────────────────────────
  Widget _buildAlertsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Alerts',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingAlerts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child:
                    CircularProgressIndicator(color: AppColors.primaryAccent),
              ),
            )
          else if (_alertError != null)
            _infoBox(
              child: Text(
                _alertError!,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.white60,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_alerts.isEmpty)
            _infoBox(
              child: const Column(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: AppColors.white60,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No active weather alerts for this location.',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: AppColors.white60,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _alerts.length,
              (i) => _AlertCard(
                alert: _alerts[i],
                onTap: () => _markRead(_alerts[i].id),
              ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Preparedness ─────────────────────────────────────────────────────────
  Widget _buildPreparednessSection(double temp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminders & Preparedness',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Go-bag: shown when typhoon / severe storm alert present
          if (_hasTyphoon)
            const _PrepCard(
              icon: Icons.backpack_rounded,
              title: 'Go-Bag Checklist',
              items: [
                'Drinking water (3-day supply)',
                'Non-perishable food',
                'First aid kit & medicines',
                'Flashlight & spare batteries',
                'Portable radio / powerbank',
                'Important documents in waterproof bag',
                'Extra clothing & sturdy shoes',
              ],
            ),

          // Heat reminders
          if (temp >= 30)
            const _PrepCard(
              icon: Icons.wb_sunny_rounded,
              title: 'Heat Index Reminders',
              items: [
                'Carry water & stay hydrated',
                'Wear sunscreen & a hat',
                'Use shade when possible',
                'Limit outdoor activity 10AM–4PM',
              ],
            ),

          // Cold reminders
          if (temp <= 5)
            const _PrepCard(
              icon: Icons.ac_unit_rounded,
              title: 'Cold Weather Reminders',
              items: [
                'Wear warm layered clothing',
                'Keep heating systems checked',
                'Watch for ice on roads',
                'Check on elderly neighbours',
              ],
            ),

          // If no specific reminder applies
          if (!_hasTyphoon && temp > 5 && temp < 30)
            const _PrepCard(
              icon: Icons.safety_check_rounded,
              title: 'General Safety Tips',
              items: [
                'Keep an emergency kit ready',
                'Stay informed via local news',
                'Know your nearest evacuation center',
                'Keep your phone charged',
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Hotlines ─────────────────────────────────────────────────────────────
  Widget _buildHotlines(List<_HotlineData> hotlines) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _infoBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Hotlines',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...hotlines.map(
              (h) => _HotlineRow(label: h.label, number: h.number),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Evacuation tips ──────────────────────────────────────────────────────
  Widget _buildEvacuationTips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _infoBox(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evacuation Tips',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _BulletItem(
              text:
                  'Stay calm, follow official alerts, and proceed to the nearest evacuation center.',
            ),
            _BulletItem(
              text: 'Bring your emergency kit and important documents.',
            ),
            _BulletItem(
              text: 'Assist children, elderly, and pets during evacuation.',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Power outage kit ─────────────────────────────────────────────────────
  Widget _buildPowerOutageKit() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _infoBox(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Power Outage Kit',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
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
    );
  }

  // ─── Footer note ──────────────────────────────────────────────────────────
  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(38)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.white60,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alerts are generated from real-time weather data '
                'via Open-Meteo. Data updates when you change location.',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: AppColors.white.withAlpha(166),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withAlpha(217),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white10),
      ),
      child: child,
    );
  }
}

// ─── Prep Card ────────────────────────────────────────────────────────────────
class _PrepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _PrepCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withAlpha(217),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.white60, size: 30),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _SimpleChecklist(items: items),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────
class _AlertCard extends StatefulWidget {
  final WeatherAlert alert;
  final VoidCallback onTap;
  const _AlertCard({required this.alert, required this.onTap});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = WeatherUtils.getAlertSeverityColor(widget.alert.severity);
    final icon = WeatherUtils.getAlertSeverityIcon(widget.alert.severity);

    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (!widget.alert.isRead) widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.alert.isRead
              ? Colors.white.withAlpha(15)
              : color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.alert.isRead
                ? Colors.white.withAlpha(31)
                : color.withAlpha(115),
            width: widget.alert.isRead ? 1 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(46),
                      borderRadius: BorderRadius.circular(12),
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
                            if (!widget.alert.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.alert.title,
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: AppColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!widget.alert.isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tempYellow.withAlpha(46),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    color: AppColors.tempYellow,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(38),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color.withAlpha(102)),
                              ),
                              child: Text(
                                widget.alert.severity.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.alert.event,
                              style: const TextStyle(
                                fontFamily: 'Rajdhani',
                                color: AppColors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.white40,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(color: AppColors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Text(
                  widget.alert.description,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    color: AppColors.white80,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────
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
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white.withAlpha(179),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: AppColors.white.withAlpha(191),
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
    final canCall = number != 'Check local listing';
    return GestureDetector(
      onTap: canCall
          ? () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label number copied.'),
                  backgroundColor: AppColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      child: Padding(
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
                  color: AppColors.white.withAlpha(217),
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              number,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: canCall ? AppColors.primaryBright : AppColors.white40,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right_rounded,
            color: AppColors.white60,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: AppColors.white.withAlpha(204),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
