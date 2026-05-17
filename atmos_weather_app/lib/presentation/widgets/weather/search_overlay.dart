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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {}); // Rebuild to show/hide suffix X icon
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      context.read<WeatherBloc>().add(const ClearSearch());
      _loadRecent();
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) context.read<WeatherBloc>().add(SearchCity(query));
    });
  }

  void _loadRecent() {
    final repo = context.read<WeatherRepository>();
    final raw = repo.getRecentLocations(max: 10);
    if (mounted) setState(() => _recent = _dedupeRecent(raw));
  }

  Future<void> _clearRecent() async {
    await context.read<WeatherRepository>().clearRecentLocations();
    if (mounted) setState(() => _recent = []);
  }

  /// Dedup by name+country+coords so both screens share the same list cleanly.
  static List<GeocodingResult> _dedupeRecent(List<GeocodingResult> items) {
    final seen = <String>{};
    final result = <GeocodingResult>[];
    for (final loc in items) {
      final key = '${loc.name.toLowerCase()}_${loc.country.toLowerCase()}_'
          '${loc.lat.toStringAsFixed(2)}_${loc.lon.toStringAsFixed(2)}';
      if (seen.add(key)) result.add(loc);
      if (result.length >= 10) break;
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
            // ── Search bar ─────────────────────────────────────────────────
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
                        hintStyle: const TextStyle(
                          fontFamily: 'Rajdhani',
                          color: AppColors.white40,
                          fontSize: 16,
                        ),
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
                                  setState(() => _isSearching = false);
                                  context
                                      .read<WeatherBloc>()
                                      .add(const ClearSearch());
                                  _loadRecent();
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

            // ── Results ────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<WeatherBloc, WeatherState>(
                builder: (context, state) {
                  if (_isSearching &&
                      state is! SearchLoaded &&
                      state is! SearchEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (state is SearchLoaded) {
                    if (state.results.isEmpty) {
                      return _buildEmpty(_controller.text);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: state.results.length,
                      itemBuilder: (context, i) {
                        final r = state.results[i];
                        return _SearchResultItem(
                          result: r,
                          onTap: () => widget.onLocationSelected(r),
                        );
                      },
                    );
                  }

                  if (state is SearchEmpty) {
                    return _buildEmpty(state.query);
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

  Widget _buildEmpty(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.white40, size: 56),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 16,
              color: AppColors.white60,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different city name',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              color: AppColors.white40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: AppColors.white40, size: 48),
            SizedBox(height: 12),
            Text(
              'No recent searches yet',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 14,
                color: AppColors.white60,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: label + Clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT SEARCHES',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white60,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton.icon(
                onPressed: _clearRecent,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.white40,
                  size: 16,
                ),
                label: const Text(
                  'Clear',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: AppColors.white40,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4),
            itemCount: _recent.length,
            itemBuilder: (context, i) {
              final r = _recent[i];
              return _SearchResultItem(
                result: r,
                isRecent: true,
                onTap: () => widget.onLocationSelected(r),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Result Item
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultItem extends StatelessWidget {
  final GeocodingResult result;
  final VoidCallback onTap;
  final bool isRecent;

  const _SearchResultItem({
    required this.result,
    required this.onTap,
    this.isRecent = false,
  });

  /// "Calauan" or "Calauan, Laguna" depending on whether admin2 is present
  String get _title {
    final province = result.admin2?.trim() ?? '';
    return province.isNotEmpty ? '${result.name}, $province' : result.name;
  }

  /// Country as subtitle
  String get _subtitle => result.country.trim();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.white10,
      highlightColor: AppColors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRecent ? Icons.history_rounded : Icons.location_on_rounded,
                color: isRecent ? AppColors.white40 : AppColors.primaryBright,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 13,
                        color: AppColors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.white40,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
