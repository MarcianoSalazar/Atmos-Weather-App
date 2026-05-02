// lib/presentation/widgets/weather/search_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/weather_model.dart';
import '../../bloc/weather/weather_bloc.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(GeocodingResult) onLocationSelected;

  const SearchOverlay({
    super.key,
    required this.onClose,
    required this.onLocationSelected,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<WeatherBloc>().add(const ClearSearch());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WeatherBloc>().add(SearchCity(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDeep.withAlpha(242),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search city or location...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.white60,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.white60,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  context
                                      .read<WeatherBloc>()
                                      .add(const ClearSearch());
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      context.read<WeatherBloc>().add(const ClearSearch());
                      widget.onClose();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: AppColors.tempYellow,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.white10, height: 1),

            // Results
            Expanded(
              child: BlocBuilder<WeatherBloc, WeatherState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryAccent),
                    );
                  }

                  if (state is SearchLoaded) {
                    return ListView.builder(
                      itemCount: state.results.length,
                      itemBuilder: (context, i) {
                        final result = state.results[i];
                        return _SearchResultItem(
                          result: result,
                          onTap: () => widget.onLocationSelected(result),
                        );
                      },
                    );
                  }

                  if (state is SearchEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppColors.white40, size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'No results for "${state.query}"',
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 16,
                              color: AppColors.white60,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Initial state - show popular cities
                  return _buildPopularCities();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCities() {
    const cities = [
      ('Manila', 'Philippines', 14.5995, 120.9842),
      ('Tokyo', 'Japan', 35.6762, 139.6503),
      ('New York', 'United States', 40.7128, -74.0060),
      ('London', 'United Kingdom', 51.5074, -0.1278),
      ('Paris', 'France', 48.8566, 2.3522),
      ('Sydney', 'Australia', -33.8688, 151.2093),
      ('Dubai', 'UAE', 25.2048, 55.2708),
      ('Singapore', 'Singapore', 1.3521, 103.8198),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'POPULAR CITIES',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white60,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: cities
                .map(
                  (c) => _SearchResultItem(
                    result: GeocodingResult(
                      name: c.$1,
                      lat: c.$3,
                      lon: c.$4,
                      country: c.$2,
                    ),
                    onTap: () => widget.onLocationSelected(
                      GeocodingResult(
                        name: c.$1,
                        lat: c.$3,
                        lon: c.$4,
                        country: c.$2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final GeocodingResult result;
  final VoidCallback onTap;

  const _SearchResultItem({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.location_on_rounded,
            color: AppColors.primaryBright, size: 20),
      ),
      title: Text(
        result.name,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      subtitle: Text(
        result.state != null
            ? '${result.state}, ${result.country}'
            : result.country,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          color: AppColors.white60,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.white40, size: 14),
      onTap: onTap,
    );
  }
}
