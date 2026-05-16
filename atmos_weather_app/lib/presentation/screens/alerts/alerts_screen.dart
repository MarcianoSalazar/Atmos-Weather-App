// lib/presentation/screens/alerts/alerts_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../bloc/weather/weather_bloc.dart';

// ---------------------------------------------------------------------------
// Emergency hotlines by country (static reference data — not weather alerts)
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Alert source tag — shown to the user so they know where the alert came from
// ---------------------------------------------------------------------------
enum _AlertSource { owmOfficial, openMeteoEstimated }

// ---------------------------------------------------------------------------
// AlertsScreen
// ---------------------------------------------------------------------------
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<WeatherAlert> _alerts = [];
  _AlertSource _alertSource = _AlertSource.openMeteoEstimated;
  bool _loadingAlerts = false;
  String? _alertError;
  String _lastFetchKey = '';

  // ---------------------------------------------------------------------------
  // Your OpenWeatherMap API key — replace with your actual key.
  // Sign up at https://openweathermap.org/api/one-call-3 (free tier available).
  // ---------------------------------------------------------------------------
  static const String _owmApiKey = 'YOUR_OWM_API_KEY_HERE';

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

  // ---------------------------------------------------------------------------
  // Main fetch: tries OWM One Call 3.0 first, falls back to open-meteo
  // ---------------------------------------------------------------------------
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

    // 1. Try OpenWeatherMap One Call 3.0 (real government / met-service alerts)
    if (_owmApiKey != 'YOUR_OWM_API_KEY_HERE') {
      final owmAlerts = await _fetchOWMAlerts(lat, lon, city, key);
      if (owmAlerts != null) {
        if (!mounted) return;
        setState(() {
          _alerts = owmAlerts;
          _alertSource = _AlertSource.owmOfficial;
          _loadingAlerts = false;
        });
        await context.read<WeatherRepository>().saveAlerts(owmAlerts);
        return;
      }
    }

    // 2. Fallback: open-meteo threshold-based alerts
    await _fetchOpenMeteoAlerts(lat, lon, city, key);
  }

  // ---------------------------------------------------------------------------
  // OWM One Call 3.0 — real alerts[]
  // Docs: https://openweathermap.org/api/one-call-3#alerts
  // ---------------------------------------------------------------------------
  Future<List<WeatherAlert>?> _fetchOWMAlerts(
    double lat,
    double lon,
    String city,
    String key,
  ) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
      final resp = await dio.get<Map<String, dynamic>>(
        'https://api.openweathermap.org/data/3.0/onecall',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': _owmApiKey,
          'exclude': 'minutely,hourly,daily',
          'units': 'metric',
        },
      );

      final data = resp.data;
      if (data == null) return null;

      final rawAlerts = data['alerts'] as List<dynamic>?;

      // OWM returns an empty list or omits the key when there are no alerts —
      // that is a valid "no alerts" response, not an error.
      if (rawAlerts == null || rawAlerts.isEmpty) return [];

      final now = DateTime.now();
      final List<WeatherAlert> alerts = [];

      for (int i = 0; i < rawAlerts.length; i++) {
        final a = rawAlerts[i] as Map<String, dynamic>;

        final senderName = (a['sender_name'] as String?) ?? 'Met Service';
        final event = (a['event'] as String?) ?? 'Weather Alert';
        final description = (a['description'] as String?) ?? '';
        final startEpoch = (a['start'] as num?)?.toInt();
        final endEpoch = (a['end'] as num?)?.toInt();
        final tags = (a['tags'] as List<dynamic>?)
                ?.map((t) => t.toString().toLowerCase())
                .toList() ??
            [];

        final startsAt = startEpoch != null
            ? DateTime.fromMillisecondsSinceEpoch(startEpoch * 1000)
            : now;
        final endsAt = endEpoch != null
            ? DateTime.fromMillisecondsSinceEpoch(endEpoch * 1000)
            : now.add(const Duration(hours: 24));

        // Infer severity from tags provided by OWM or from event text
        final severity = _inferSeverityFromTags(tags, event);

        alerts.add(WeatherAlert(
          id: 'owm_${key}_$i',
          title: event,
          description: description.isNotEmpty
              ? description
              : 'Alert issued by $senderName. Check local advisories for details.',
          severity: severity,
          event: event,
          startsAt: startsAt,
          endsAt: endsAt,
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      return alerts;
    } on DioException {
      // Network or HTTP error — fall through to open-meteo
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Derives a human-readable severity from OWM alert tags.
  /// OWM tags can include: "Extreme", "Severe", "Moderate", "Minor",
  /// "Wind", "Rain", "Fog", "Snow", "Thunderstorm", etc.
  String _inferSeverityFromTags(List<String> tags, String event) {
    for (final tag in tags) {
      if (tag == 'extreme') return 'Extreme';
      if (tag == 'severe') return 'Severe';
      if (tag == 'moderate') return 'Moderate';
      if (tag == 'minor') return 'Minor';
    }
    // Fall back to keyword matching in the event title
    final e = event.toLowerCase();
    if (e.contains('extreme') ||
        e.contains('typhoon') ||
        e.contains('cyclone') ||
        e.contains('tornado')) {
      return 'Extreme';
    }
    if (e.contains('severe') || e.contains('warning') || e.contains('danger')) {
      return 'Severe';
    }
    if (e.contains('watch') || e.contains('advisory')) return 'Moderate';
    return 'Minor';
  }

  // ---------------------------------------------------------------------------
  // Open-Meteo dynamic alert generation
  //
  // Strategy: fetch current + 3-day daily data from Open-Meteo, then derive
  // alerts **only** from actual API values — no hardcoded thresholds that fire
  // regardless of real conditions.  Each alert is generated only when the
  // corresponding metric exceeds a meaningful danger level.
  //
  // WMO weather code reference (subset used here):
  //   0        → Clear sky
  //   1–3      → Mainly clear / partly cloudy / overcast
  //   45, 48   → Fog / depositing rime fog
  //   51–55    → Drizzle (light → dense)
  //   61–65    → Rain (slight → heavy)
  //   71–75    → Snow (slight → heavy)
  //   80–82    → Rain showers (slight → violent)
  //   95       → Thunderstorm (slight/moderate)
  //   96, 99   → Thunderstorm with hail (slight / heavy)
  // ---------------------------------------------------------------------------
  Future<void> _fetchOpenMeteoAlerts(
    double lat,
    double lon,
    String city,
    String key,
  ) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

      // ── Primary request: current + 3-day daily ──────────────────────────
      final resp = await dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'weather_code',
            'wind_speed_10m',
            'wind_gusts_10m',
            'precipitation',
            'surface_pressure',
            'relative_humidity_2m',
            'visibility',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_sum',
            'precipitation_probability_max',
            'wind_speed_10m_max',
            'wind_gusts_10m_max',
            'uv_index_max',
          ].join(','),
          'timezone': 'auto',
          'forecast_days': 1,
        },
      );

      final data = resp.data!;
      final cur = data['current'] as Map<String, dynamic>? ?? {};
      final daily = data['daily'] as Map<String, dynamic>? ?? {};

      final alerts = <WeatherAlert>[];
      final now = DateTime.now();

      // ── Parse current values ─────────────────────────────────────────────
      final temp = (cur['temperature_2m'] as num?)?.toDouble() ?? 0.0;
      final feelsLike =
          (cur['apparent_temperature'] as num?)?.toDouble() ?? temp;
      final windSpeed = (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final windGust = (cur['wind_gusts_10m'] as num?)?.toDouble() ?? windSpeed;
      final precip = (cur['precipitation'] as num?)?.toDouble() ?? 0.0;
      final pressure = (cur['surface_pressure'] as num?)?.toDouble() ?? 1013.0;
      final humidity = (cur['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0;
      final visibility = (cur['visibility'] as num?)?.toDouble() ?? 10000.0;
      final wCode = (cur['weather_code'] as num?)?.toInt() ?? 0;

      // ── Parse daily arrays ───────────────────────────────────────────────
      List<T> parseList<T>(String field, T Function(num?) parse) =>
          (daily[field] as List?)?.map((e) => parse(e as num?)).toList() ?? [];

      final dailyCodes =
          parseList<int>('weather_code', (n) => n?.toInt() ?? 0);
      final dailyMaxTemps =
          parseList<double>('temperature_2m_max', (n) => n?.toDouble() ?? 0);
      final dailyPrecipSums =
          parseList<double>('precipitation_sum', (n) => n?.toDouble() ?? 0);
      final dailyPrecipProb = parseList<int>(
          'precipitation_probability_max', (n) => n?.toInt() ?? 0);
      final dailyWindMax =
          parseList<double>('wind_speed_10m_max', (n) => n?.toDouble() ?? 0);
      final dailyGustMax =
          parseList<double>('wind_gusts_10m_max', (n) => n?.toDouble() ?? 0);
      final dailyUvMax =
          parseList<double>('uv_index_max', (n) => n?.toDouble() ?? 0);

      // ════════════════════════════════════════════════════════════════════════
      // ALERT RULES — today only (index 0 of daily arrays).
      // All checks use today's daily values combined with live current readings.
      // ════════════════════════════════════════════════════════════════════════

      // Convenience: today's daily values (index 0)
      final todayCode = dailyCodes.elementAtOrNull(0) ?? wCode;
      final todayMaxTemp = dailyMaxTemps.elementAtOrNull(0) ?? temp;
      final todayPrecip = dailyPrecipSums.elementAtOrNull(0) ?? precip;
      final todayPrecipProb = dailyPrecipProb.elementAtOrNull(0) ?? 100;
      final todayWindMax = dailyWindMax.elementAtOrNull(0) ?? windSpeed;
      final todayGustMax = dailyGustMax.elementAtOrNull(0) ?? windGust;
      final todayUv = dailyUvMax.elementAtOrNull(0) ?? 0.0;

      // ── 1. Severe thunderstorm (WMO 95–99 today) ─────────────────────────
      if (todayCode >= 95) {
        final isSevere = todayCode >= 96; // 96/99 = with hail
        alerts.add(WeatherAlert(
          id: 'thunderstorm_$key',
          title: isSevere
              ? 'Severe Thunderstorm Warning'
              : 'Thunderstorm Advisory',
          description: isSevere
              ? 'A severe thunderstorm with hail is occurring or expected today near $city. '
                  'Wind gusts may reach ${todayGustMax.round()} km/h. '
                  'Stay indoors, avoid open areas and tall objects. '
                  'Monitor official advisories closely.'
              : 'A thunderstorm is expected today near $city. '
                  'Wind gusts may reach ${todayGustMax.round()} km/h with heavy rain. '
                  'Avoid outdoor activities during the storm.',
          severity: isSevere ? 'Extreme' : 'Severe',
          event: isSevere ? 'Severe Thunderstorm' : 'Thunderstorm',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 12)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // ── 2. Heavy rain today (daily sum ≥ 30 mm with ≥ 60% probability,
      //        OR active precipitation ≥ 5 mm right now) ───────────────────
      // Skip if thunderstorm alert already covers today.
      if (todayCode < 95) {
        final isActiveNow = precip >= 5;
        if ((todayPrecip >= 30 && todayPrecipProb >= 60) || isActiveNow) {
          alerts.add(WeatherAlert(
            id: 'heavyrain_$key',
            title: todayPrecip >= 80
                ? 'Heavy Rain Warning'
                : 'Heavy Rain Advisory',
            description: isActiveNow && todayPrecip < 30
                ? 'Heavy precipitation of ${precip.toStringAsFixed(1)} mm is currently '
                    'falling near $city. Flash flooding of low-lying areas is possible. '
                    'Motorists should exercise caution and avoid flooded roads.'
                : 'Significant rainfall of up to ${todayPrecip.round()} mm '
                    '($todayPrecipProb% probability) is expected today near $city. '
                    'Flash flooding of low-lying areas is possible. '
                    'Motorists should exercise caution and avoid flooded roads.',
            severity: todayPrecip >= 80 ? 'Severe' : 'Moderate',
            event: 'Heavy Rain',
            startsAt: now,
            endsAt: now.add(const Duration(hours: 24)),
            isRead: false,
            lat: lat,
            lon: lon,
          ));
        }
      }

      // ── 3. Strong wind today (sustained ≥ 50 km/h or gusts ≥ 70 km/h) ──
      if (todayWindMax >= 50 || todayGustMax >= 70) {
        alerts.add(WeatherAlert(
          id: 'wind_$key',
          title: todayGustMax >= 90
              ? 'Destructive Wind Warning'
              : 'Strong Wind Warning',
          description:
              'Sustained winds of ${todayWindMax.round()} km/h with gusts '
              'up to ${todayGustMax.round()} km/h are expected today near $city. '
              'Secure loose outdoor objects. Residents in exposed areas '
              'should take precautionary measures.',
          severity: todayGustMax >= 90
              ? 'Extreme'
              : (todayGustMax >= 70 ? 'Severe' : 'Moderate'),
          event: 'Strong Wind',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 18)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // ── 4. Extreme heat today (daily max ≥ 38 °C) ────────────────────────
      if (todayMaxTemp >= 38) {
        final isExtreme = todayMaxTemp >= 42 || feelsLike >= 45;
        alerts.add(WeatherAlert(
          id: 'heat_$key',
          title: isExtreme ? 'Extreme Heat Warning' : 'Heat Advisory',
          description: 'Dangerous heat of ${todayMaxTemp.round()}°C '
              '(currently feels like ${feelsLike.round()}°C) is forecast today near $city. '
              'Limit outdoor activities between 10 AM and 4 PM. '
              'Stay hydrated, use cooling centres, and check on vulnerable individuals.',
          severity: isExtreme ? 'Extreme' : 'Severe',
          event: 'Extreme Heat',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 24)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // ── 5. High UV today (daily max ≥ 8) ─────────────────────────────────
      if (todayUv >= 8) {
        alerts.add(WeatherAlert(
          id: 'uv_$key',
          title: todayUv >= 11
              ? 'Extreme UV Index Warning'
              : 'High UV Index Advisory',
          description: 'UV index is forecast to reach ${todayUv.round()} '
              '(${WeatherUtils.getUVLabel(todayUv)}) today near $city. '
              'Apply SPF 50+ sunscreen, wear UV-protective clothing and sunglasses. '
              'Minimise direct sun exposure between 10 AM and 3 PM.',
          severity: todayUv >= 11 ? 'Extreme' : 'Severe',
          event: 'High UV',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 10)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // ── 6. Current-conditions alerts (fire once for now) ──────────────────

      // Dense fog — WMO 45/48 or visibility < 1 km
      if (wCode == 45 || wCode == 48 || visibility < 1000) {
        alerts.add(WeatherAlert(
          id: 'fog_$key',
          title: 'Dense Fog Advisory',
          description: 'Dense fog is currently affecting $city '
              '${visibility < 1000 ? 'with visibility as low as ${(visibility / 1000).toStringAsFixed(1)} km' : 'with visibility below 200 m'}. '
              'Reduce speed, increase following distance, and use fog lights when driving.',
          severity: 'Minor',
          event: 'Dense Fog',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 6)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // Low atmospheric pressure — active storm system indicator
      if (pressure < 990) {
        alerts.add(WeatherAlert(
          id: 'pressure_$key',
          title: 'Low Pressure System Detected',
          description: 'A low pressure system of ${pressure.round()} hPa '
              'is currently present near $city, '
              'indicating an active or developing storm. '
              'Expect unsettled weather with potential heavy rain and strong winds.',
          severity: pressure < 975 ? 'Severe' : 'Moderate',
          event: 'Low Pressure',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 24)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      // Very high humidity — discomfort / health risk (tropical threshold)
      if (humidity >= 90 && temp >= 30) {
        alerts.add(WeatherAlert(
          id: 'humidity_$key',
          title: 'High Heat & Humidity Advisory',
          description:
              'Relative humidity of ${humidity.round()}% combined with '
              'a temperature of ${temp.round()}°C near $city '
              'creates oppressive conditions. '
              'The heat index may feel significantly higher than the actual temperature. '
              'Stay hydrated and avoid strenuous outdoor activity.',
          severity: 'Minor',
          event: 'High Humidity',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 12)),
          isRead: false,
          lat: lat,
          lon: lon,
        ));
      }

      if (mounted) {
        setState(() {
          _alerts = alerts;
          _alertSource = _AlertSource.openMeteoEstimated;
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

  // ---------------------------------------------------------------------------
  // Read / mark helpers
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
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
                    _lastFetchKey = ''; // force re-fetch
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
                          child: _buildHeader(cityName, country)),
                      SliverToBoxAdapter(
                          child: _buildAlertBanner(cityName, country)),
                      SliverToBoxAdapter(child: _buildAlertsList()),
                      SliverToBoxAdapter(
                          child: _buildPreparednessSection(currentTemp)),
                      SliverToBoxAdapter(child: _buildHotlines(hotlines)),
                      SliverToBoxAdapter(child: _buildEvacuationTips()),
                      SliverToBoxAdapter(child: _buildPowerOutageKit()),
                      SliverToBoxAdapter(child: _buildFooterNote()),
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

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
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
          if (_unreadCount > 0)
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alert banner
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Alerts list
  // ---------------------------------------------------------------------------
  Widget _buildAlertsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              // Source badge
              if (!_loadingAlerts && _alertError == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _alertSource == _AlertSource.owmOfficial
                        ? Colors.green.withAlpha(46)
                        : Colors.orange.withAlpha(46),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _alertSource == _AlertSource.owmOfficial
                          ? Colors.green.withAlpha(102)
                          : Colors.orange.withAlpha(102),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _alertSource == _AlertSource.owmOfficial
                            ? Icons.verified_rounded
                            : Icons.science_outlined,
                        color: _alertSource == _AlertSource.owmOfficial
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _alertSource == _AlertSource.owmOfficial
                            ? 'OFFICIAL'
                            : 'ESTIMATED',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _alertSource == _AlertSource.owmOfficial
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

  // ---------------------------------------------------------------------------
  // Preparedness section
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Hotlines
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Evacuation tips
  // ---------------------------------------------------------------------------
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
                text: 'Bring your emergency kit and important documents.'),
            _BulletItem(
              text: 'Assist children, elderly, and pets during evacuation.',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Power outage kit
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Footer note — updated to mention both sources
  // ---------------------------------------------------------------------------
  Widget _buildFooterNote() {
    final sourceText = _alertSource == _AlertSource.owmOfficial
        ? 'Official alerts are sourced from OpenWeatherMap One Call 3.0 '
            '(government / meteorological service feeds). '
            'Data refreshes when you change location or pull to refresh.'
        : 'No official alerts found for this location. '
            'Estimated alerts are generated from real-time open-meteo data '
            'using WMO weather codes and meteorological thresholds.';

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
                sourceText,
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

// =============================================================================
// Supporting widgets (unchanged from original)
// =============================================================================

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
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 22),
                      ),
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
                                    horizontal: 7, vertical: 2),
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
                                  horizontal: 6, vertical: 2),
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
                            Flexible(
                              child: Text(
                                widget.alert.event,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: AppColors.white60,
                                  fontSize: 12,
                                ),
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
