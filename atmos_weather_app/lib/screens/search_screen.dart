import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _showResults = false;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final lat = provider.currentLat ?? 12.8797;
        final lon = provider.currentLon ?? 121.7740;

        return Stack(
          children: [
            // Full screen map background
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lon),
                initialZoom: 7.0,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.atmos.weather',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lon),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AtmosTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AtmosTheme.primaryBlue.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Search bar + results overlay
            Column(
              children: [
                // Search bar
                Container(
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
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search city or location...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.white70, size: 18),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 16),
                              onPressed: () {
                                _controller.clear();
                                provider.clearSearch();
                                setState(() => _showResults = false);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) {
                      setState(() => _showResults = v.length >= 2);
                      provider.searchCities(v);
                    },
                  ),
                ),

                // Search Results
                if (_showResults) ...[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: provider.isSearching
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : provider.searchResults.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No locations found',
                                      style: TextStyle(
                                        color: AtmosTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: provider.searchResults.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: AtmosTheme.divider),
                                  itemBuilder: (context, index) {
                                    final result =
                                        provider.searchResults[index];
                                    final name = result['name'] ?? '';
                                    final state = result['state'] ?? '';
                                    final country = result['country'] ?? '';
                                    final display = [name, state, country]
                                        .where((e) => e.isNotEmpty)
                                        .join(', ');
                                    final subtitle = state.isNotEmpty
                                        ? '$state, $country'
                                        : country;

                                    return ListTile(
                                      leading: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AtmosTheme.lightBlue,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.location_on_rounded,
                                            color: AtmosTheme.primaryBlue,
                                            size: 18),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: AtmosTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        subtitle,
                                        style: const TextStyle(
                                          color: AtmosTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () {
                                        _controller.text = display;
                                        setState(() => _showResults = false);
                                        provider.clearSearch();
                                        provider.loadWeatherByCity(name);
                                        // Update map
                                        final lat = (result['lat'] ?? 12.8797)
                                            .toDouble();
                                        final lon = (result['lon'] ?? 121.7740)
                                            .toDouble();
                                        _mapController.move(
                                            LatLng(lat, lon), 10);
                                        // Go to home
                                        Future.delayed(
                                            const Duration(milliseconds: 500),
                                            () {
                                          if (mounted) {
                                            provider.setNavIndex(0);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
