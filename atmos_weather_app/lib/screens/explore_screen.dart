import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late MapController _mapController;
  bool _panelExpanded = false;

  // Mock evacuation centers near Santa Cruz, Laguna
  final List<Map<String, dynamic>> _evacuationCenters = [
    {
      'name': 'Santa Cruz Community Hall',
      'distance': '1.7 km',
      'lat': 14.2791,
      'lon': 121.4157,
    },
    {
      'name': 'Laguna Sports Complex',
      'distance': '2.4 km',
      'lat': 14.2850,
      'lon': 121.4200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final weather = provider.currentWeather;
        final lat = provider.currentLat ?? 14.2791;
        final lon = provider.currentLon ?? 121.4157;
        final hourly = provider.hourlyForecast;

        return Stack(
          children: [
            // Full screen satellite map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lon),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.atmos.weather',
                ),
                MarkerLayer(
                  markers: [
                    // User location
                    Marker(
                      point: LatLng(lat, lon),
                      width: 40,
                      height: 40,
                      child: _PulsingMarker(),
                    ),
                    // Evacuation centers
                    ..._evacuationCenters.map((center) => Marker(
                          point:
                              LatLng(center['lat'], center['lon']),
                          width: 36,
                          height: 36,
                          child: Tooltip(
                            message: center['name'],
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                  Icons.local_hospital_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ),
                        )),
                  ],
                ),
                // Safe route overlay (polyline)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(lat, lon),
                        LatLng(_evacuationCenters[0]['lat'],
                            _evacuationCenters[0]['lon']),
                      ],
                      color: const Color(0xFF43A047),
                      strokeWidth: 3,
                    ),
                    Polyline(
                      points: [
                        LatLng(lat, lon),
                        LatLng(_evacuationCenters[1]['lat'],
                            _evacuationCenters[1]['lon']),
                      ],
                      color: const Color(0xFFFDD835),
                      strokeWidth: 3,
                      isDotted: true,
                    ),
                  ],
                ),
              ],
            ),

            // Top search bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: AtmosSearchBar(
                  hint: 'Search location...',
                  onSubmitted: (v) {
                    if (v.isNotEmpty) provider.loadWeatherByCity(v);
                  },
                ),
              ),
            ),

            // Bottom info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _panelExpanded = !_panelExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AtmosTheme.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Location name
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AtmosTheme.primaryBlue, size: 16),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather?.cityName ?? 'Current Location',
                                  style: const TextStyle(
                                    color: AtmosTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  weather?.country ?? '',
                                  style: const TextStyle(
                                    color: AtmosTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _ActionBtn(
                                    icon: Icons.bookmark_border_rounded),
                                const SizedBox(width: 8),
                                _ActionBtn(icon: Icons.share_rounded),
                                const SizedBox(width: 8),
                                _ActionBtn(icon: Icons.close_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (weather != null) ...[
                        // Current Weather + Alert info grid
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // Current Weather
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AtmosTheme.lightBlue
                                        .withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _capitalize(
                                            weather.description),
                                        style: const TextStyle(
                                          color: AtmosTheme.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${weather.temperature.round()}°C',
                                        style: const TextStyle(
                                          color: AtmosTheme.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Feels like ${weather.feelsLike.round()}°C',
                                        style: const TextStyle(
                                          color: AtmosTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'Wind: ${WeatherUtils.formatWindSpeed(weather.windSpeed)}',
                                        style: const TextStyle(
                                          color: AtmosTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'Chance: ${provider.forecast.isNotEmpty ? provider.forecast[0].rainChance.round() : 0}%',
                                        style: const TextStyle(
                                          color: AtmosTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Weather Alert
                              if (provider.alerts.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE0E0),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                                Icons.warning_amber_rounded,
                                                color:
                                                    Color(0xFFE53935),
                                                size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Weather Alert',
                                              style: TextStyle(
                                                color: Color(0xFFE53935),
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          provider.alerts[0].description,
                                          style: const TextStyle(
                                            color: AtmosTheme.textPrimary,
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // Safest Routes
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Safest Routes',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _RouteItem(
                                        label: 'Route A',
                                        tag: 'Flood Safe',
                                        color: const Color(0xFF43A047),
                                      ),
                                      const SizedBox(height: 4),
                                      _RouteItem(
                                        label: 'Route B',
                                        tag: 'Light Traffic',
                                        color: const Color(0xFFFDD835),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Evacuation Centers
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nearby Evacuation Centers',
                                        style: TextStyle(
                                          color: AtmosTheme.primaryBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ..._evacuationCenters.map((c) =>
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    bottom: 4),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .local_hospital_rounded,
                                                  color: Color(0xFF43A047),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${c['name']} (${c['distance']})',
                                                    style:
                                                        const TextStyle(
                                                      color: AtmosTheme
                                                          .textPrimary,
                                                      fontSize: 10,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Hourly Strip
                      if (hourly.isNotEmpty) ...[
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: hourly.take(8).length,
                            itemBuilder: (context, index) {
                              final h = hourly[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      index == 0
                                          ? 'Now'
                                          : WeatherUtils.formatHour(
                                              h.time),
                                      style: TextStyle(
                                        color: AtmosTheme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    WeatherIconWidget(
                                        iconCode: h.iconCode, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      WeatherUtils.formatTemp(
                                          h.temperature),
                                      style: const TextStyle(
                                        color: AtmosTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _PulsingMarker extends StatefulWidget {
  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40 * _animation.value,
            height: 40 * _animation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AtmosTheme.primaryBlue
                  .withOpacity(0.3 * (1 - _animation.value + 0.5)),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AtmosTheme.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteItem extends StatelessWidget {
  final String label;
  final String tag;
  final Color color;

  const _RouteItem({
    required this.label,
    required this.tag,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              color: AtmosTheme.textPrimary, fontSize: 11),
        ),
        const SizedBox(width: 4),
        Text(
          '· $tag',
          style: TextStyle(color: color, fontSize: 10),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;

  const _ActionBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AtmosTheme.divider,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AtmosTheme.textSecondary, size: 16),
    );
  }
}
