import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final lat = provider.currentLat ?? 14.2791;
        final lon = provider.currentLon ?? 121.4157;

        return Stack(
          children: [
            // ── Satellite Map (full screen background) ────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lon),
                initialZoom: 9.5,
                minZoom: 3,
                maxZoom: 18,
                onTap: (_, __) {
                  // Close results when tapping map
                  if (_showResults) {
                    setState(() => _showResults = false);
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
              children: [
                // ESRI Satellite tiles — matches wireframe
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.atmos.weather',
                ),
                // Current location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lon),
                      width: 44,
                      height: 44,
                      child: _LocationPin(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Top: Search bar + results ─────────────────────────────────
            Column(
              children: [
                // Search bar row (matches wireframe — white bg, search icon right)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                        color: AtmosTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search city or location...',
                      hintStyle: const TextStyle(
                          color: AtmosTheme.textLight, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AtmosTheme.textLight, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.clearSearch();
                                setState(() => _showResults = false);
                              },
                            )
                          : const Icon(Icons.search_rounded,
                              color: AtmosTheme.textSecondary, size: 20),
                    ),
                    onChanged: (v) {
                      setState(() => _showResults = v.length >= 2);
                      if (v.length >= 2) provider.searchCities(v);
                    },
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        provider.loadWeatherByCity(v);
                        setState(() => _showResults = false);
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                        // Go to home after city selected
                        Future.delayed(const Duration(milliseconds: 300),
                            () => provider.setNavIndex(0));
                      }
                    },
                  ),
                ),

                // ── Search results list — white panel matching wireframe ──
                if (_showResults)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: provider.isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          )
                        : provider.searchResults.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No locations found',
                                  style: TextStyle(
                                      color: AtmosTheme.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: provider.searchResults.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: AtmosTheme.divider),
                                itemBuilder: (context, i) {
                                  final r = provider.searchResults[i];
                                  final name = r['name'] ?? '';
                                  final state = r['state'] ?? '';
                                  final country = r['country'] ?? '';

                                  // Distance placeholder — matches wireframe style
                                  final subLine = [state, country]
                                      .where((e) => e.isNotEmpty)
                                      .join(', ');

                                  return _SearchResultTile(
                                    name: name,
                                    subtitle: subLine,
                                    onTap: () {
                                      _searchCtrl.clear();
                                      provider.clearSearch();
                                      setState(() => _showResults = false);
                                      FocusScope.of(context).unfocus();

                                      // Move map to selected location
                                      final rLat =
                                          (r['lat'] ?? lat).toDouble();
                                      final rLon =
                                          (r['lon'] ?? lon).toDouble();
                                      _mapController.move(
                                          LatLng(rLat, rLon), 11);

                                      // Load weather for selected city
                                      provider.loadWeatherByCity(name);

                                      // Navigate home after short delay
                                      Future.delayed(
                                          const Duration(
                                              milliseconds: 400),
                                          () => provider.setNavIndex(0));
                                    },
                                  );
                                },
                              ),
                  ),
              ],
            ),

            // ── Map control buttons (top-right) ───────────────────────────
            if (!_showResults)
              Positioned(
                top: 60,
                right: 12,
                child: Column(
                  children: [
                    _MapBtn(
                      icon: Icons.my_location_rounded,
                      onTap: () =>
                          _mapController.move(LatLng(lat, lon), 12),
                      tooltip: 'My Location',
                    ),
                    const SizedBox(height: 8),
                    _MapBtn(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                      tooltip: 'Zoom In',
                    ),
                    const SizedBox(height: 4),
                    _MapBtn(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                      tooltip: 'Zoom Out',
                    ),
                  ],
                ),
              ),

            // ── Bottom location chip ──────────────────────────────────────
            if (!_showResults && provider.currentWeather != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _LocationChip(provider: provider),
              ),
          ],
        );
      },
    );
  }
}

// ── Location pin marker ───────────────────────────────────────────────────────
class _LocationPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AtmosTheme.primaryBlue.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        // Inner dot
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AtmosTheme.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AtmosTheme.primaryBlue.withOpacity(0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Search result tile — matches wireframe style ──────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Distance badge — like the "2.8 km" in the wireframe
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AtmosTheme.lightBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: AtmosTheme.primaryBlue, size: 12),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AtmosTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AtmosTheme.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AtmosTheme.textLight, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Bottom location chip ──────────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  final WeatherProvider provider;
  const _LocationChip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = provider.currentWeather!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Weather icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AtmosTheme.lightBlue.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              WeatherUtils.getWeatherIcon(w.mainCondition),
              color: AtmosTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${w.cityName}, ${w.country}',
                  style: const TextStyle(
                    color: AtmosTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${w.temperature.round()}°C · ${_cap(w.description)}',
                  style: const TextStyle(
                    color: AtmosTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons — bookmark / share / close
          Row(
            children: [
              _ChipBtn(
                icon: Icons.bookmark_border_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${w.cityName} saved!'),
                      backgroundColor: AtmosTheme.primaryBlue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              _ChipBtn(icon: Icons.share_rounded, onTap: () {}),
              const SizedBox(width: 6),
              _ChipBtn(
                icon: Icons.close_rounded,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ChipBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ChipBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AtmosTheme.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AtmosTheme.textSecondary, size: 15),
      ),
    );
  }
}

// ── Map control button ────────────────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _MapBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AtmosTheme.textPrimary, size: 20),
        ),
      ),
    );
  }
}
