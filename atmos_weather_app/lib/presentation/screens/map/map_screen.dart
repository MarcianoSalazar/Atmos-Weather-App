// lib/presentation/screens/map/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/settings_controller.dart';
import '../../bloc/weather/weather_bloc.dart';

enum MapLayer { temperature, precipitation, clouds, wind, pressure }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final SettingsController _settingsController = SettingsController.instance;
  MapLayer _selectedLayer = MapLayer.temperature;
  bool _showLayerPanel = false;
  double _opacity = 0.7;
  LatLng _center = const LatLng(14.5995, 120.9842);

  final Map<MapLayer, Map<String, dynamic>> _layers = {
    MapLayer.temperature: {
      'label': 'Temperature',
      'icon': Icons.thermostat_rounded,
      'owmLayer': 'temp_new',
      'color': const Color(0xFFFF7043),
      'description': 'Surface temperature distribution',
    },
    MapLayer.precipitation: {
      'label': 'Precipitation',
      'icon': Icons.water_drop_rounded,
      'owmLayer': 'precipitation_new',
      'color': const Color(0xFF42A5F5),
      'description': 'Rainfall and precipitation intensity',
    },
    MapLayer.clouds: {
      'label': 'Clouds',
      'icon': Icons.cloud_rounded,
      'owmLayer': 'clouds_new',
      'color': const Color(0xFFB0BEC5),
      'description': 'Cloud coverage and density',
    },
    MapLayer.wind: {
      'label': 'Wind',
      'icon': Icons.air_rounded,
      'owmLayer': 'wind_new',
      'color': const Color(0xFF81D4FA),
      'description': 'Wind speed at surface level',
    },
    MapLayer.pressure: {
      'label': 'Pressure',
      'icon': Icons.compress_rounded,
      'owmLayer': 'pressure_new',
      'color': const Color(0xFF9C27B0),
      'description': 'Atmospheric pressure levels',
    },
  };

  @override
  void initState() {
    super.initState();
    _settingsController.addListener(_handleSettingsUpdate);
    _settingsController.load();
    // Set initial center from weather state
    final state = context.read<WeatherBloc>().state;
    if (state is WeatherLoaded) {
      _center = LatLng(state.lat, state.lon);
    }
  }

  @override
  void dispose() {
    _settingsController.removeListener(_handleSettingsUpdate);
    super.dispose();
  }

  void _handleSettingsUpdate() {
    if (mounted) setState(() {});
  }

  String get _baseTileUrl {
    final style = _settingsController.settings.mapStyle;
    switch (style) {
      case 'light':
        return AppConstants.cartoLightTileUrl;
      case 'satellite':
        return AppConstants.esriWorldImageryTileUrl;
      case 'dark':
      default:
        return AppConstants.cartoDarkTileUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Stack(
        children: [
          // Map
          BlocListener<WeatherBloc, WeatherState>(
            listener: (context, state) {
              if (state is WeatherLoaded) {
                final nextCenter = LatLng(state.lat, state.lon);
                _center = nextCenter;
                _mapController.move(nextCenter, _mapController.camera.zoom);
              }
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 6,
                minZoom: 2,
                maxZoom: 18,
                onMapReady: () {},
              ),
              children: [
                // Base tile layer
                TileLayer(
                  urlTemplate: _baseTileUrl,
                  userAgentPackageName: 'com.atmos.weather',
                  tileProvider: NetworkTileProvider(),
                ),

                // Weather overlay layer
                if (AppConstants.openWeatherApiKey !=
                    'YOUR_OPENWEATHERMAP_API_KEY')
                  Opacity(
                    opacity: _opacity,
                    child: TileLayer(
                      urlTemplate:
                          'https://tile.openweathermap.org/map/${_layers[_selectedLayer]!['owmLayer']}/{z}/{x}/{y}.png?appid=${AppConstants.openWeatherApiKey}',
                      userAgentPackageName: 'com.atmos.weather',
                      tileProvider: NetworkTileProvider(),
                    ),
                  ),

                // Location marker
                BlocBuilder<WeatherBloc, WeatherState>(
                  builder: (context, state) {
                    if (state is! WeatherLoaded) return const SizedBox();
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(state.lat, state.lon),
                          width: 170,
                          height: 96,
                          child: _LocationMarker(cityName: state.cityName),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildBottomControls(),
              ],
            ),
          ),

          // Layer panel
          if (_showLayerPanel) _buildLayerPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final layerData = _layers[_selectedLayer]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Active layer chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: (layerData['color'] as Color).withOpacity(0.5),),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(layerData['icon'] as IconData,
                    color: layerData['color'] as Color, size: 18,),
                const SizedBox(width: 8),
                Text(
                  layerData['label'] as String,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Layers button
          GestureDetector(
            onTap: () => setState(() => _showLayerPanel = !_showLayerPanel),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.layers_rounded,
                      color: AppColors.white, size: 18,),
                  SizedBox(width: 6),
                  Text(
                    'Layers',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Row(
        children: [
          // Opacity control
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAYER OPACITY',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      color: AppColors.white60,
                      letterSpacing: 1,
                    ),
                  ),
                  SliderTheme(
                    data: const SliderThemeData(
                      trackHeight: 3,
                      thumbShape:
                          RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _opacity,
                      onChanged: (v) => setState(() => _opacity = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Location button
          GestureDetector(
            onTap: () {
              final state = context.read<WeatherBloc>().state;
              if (state is WeatherLoaded) {
                _mapController.move(LatLng(state.lat, state.lon), 10);
              }
            },
            child: Container(
              width: 48,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white20),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.tempYellow,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() => _showLayerPanel = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // prevent dismiss
              child: Container(
                margin: const EdgeInsets.fromLTRB(100, 70, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        'WEATHER LAYERS',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white60,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.white10, height: 1),
                    ...MapLayer.values.map((layer) {
                      final data = _layers[layer]!;
                      final isSelected = _selectedLayer == layer;
                      return ListTile(
                        leading: Icon(
                          data['icon'] as IconData,
                          color: isSelected
                              ? data['color'] as Color
                              : AppColors.white60,
                          size: 22,
                        ),
                        title: Text(
                          data['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.white80,
                          ),
                        ),
                        subtitle: Text(
                          data['description'] as String,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11,
                            color: AppColors.white60,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: data['color'] as Color,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLayer = layer;
                            _showLayerPanel = false;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final String cityName;

  const _LocationMarker({required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.tempYellow.withOpacity(0.7)),
            ),
            child: Text(
              cityName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.tempYellow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.tempYellow.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
