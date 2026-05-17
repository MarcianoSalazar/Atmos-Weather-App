// lib/presentation/widgets/weather/search_overlay.dart

import 'package:atmos/data/repositories/weather_repository.dart';
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
  List<GeocodingResult> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

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
      _loadRecent();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WeatherBloc>().add(SearchCity(query));
    });
  }

  void _loadRecent() {
    final repo = context.read<WeatherRepository>();
    final raw = repo.getRecentLocations(max: 20);
    setState(() {
      _recent = _dedupeRecent(raw);
    });
  }

  static List<GeocodingResult> _dedupeRecent(List<GeocodingResult> items) {
    final seen = <String>{};
    final result = <GeocodingResult>[];
    for (final loc in items) {
      final key = '${loc.lat.toStringAsFixed(2)}_${loc.lon.toStringAsFixed(2)}';
      if (seen.add(key)) result.add(loc);
      if (result.length >= 8) break;
    }
    return result;
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
                        color: AppColors.primaryAccent,
                      ),
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
                          const Icon(
                            Icons.search_off_rounded,
                            color: AppColors.white40,
                            size: 56,
                          ),
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

                  return _buildRecentSearches();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recent.isEmpty) {
      return const Center(
        child: Text(
          'No recent searches yet',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            color: AppColors.white60,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'RECENT SEARCHES',
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
            children: _recent
                .map(
                  (r) => _SearchResultItem(
                    result: r,
                    onTap: () => widget.onLocationSelected(r),
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

  /// Title logic:
  ///   - Has province (admin2) → "Calauan, Laguna"
  ///   - No province           → "Calauan"
  String get _title {
    final province = result.admin2?.trim() ?? '';
    if (province.isNotEmpty) return '${result.name}, $province';
    return result.name;
  }

  /// Subtitle shows only the country.
  String get _subtitle => result.country.trim();

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
        child: const Icon(
          Icons.location_on_rounded,
          color: AppColors.primaryBright,
          size: 20,
        ),
      ),
      title: Text(
        _title,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitle,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          color: AppColors.white60,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.white40,
        size: 14,
      ),
      onTap: onTap,
    );
  }
}
