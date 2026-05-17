// lib/presentation/screens/home/home_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:atmos/presentation/bloc/weather/weather_bloc.dart';
import 'package:atmos/presentation/widgets/weather/current_weather_card.dart';
import 'package:atmos/presentation/widgets/weather/hourly_forecast_widget.dart';
import 'package:atmos/presentation/widgets/weather/daily_forecast_widget.dart';
import 'package:atmos/presentation/widgets/weather/weather_details_grid.dart';
import 'package:atmos/presentation/widgets/weather/air_quality_card.dart';
import 'package:atmos/presentation/widgets/weather/search_overlay.dart';
import 'package:atmos/core/theme/app_theme.dart';
import 'package:atmos/core/utils/settings_controller.dart';
import 'package:atmos/core/utils/weather_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  final SettingsController _settingsController = SettingsController.instance;
  bool _showSearch = false;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _settingsController.addListener(_onSettingsChanged);
    final bloc = context.read<WeatherBloc>();
    if (bloc.state is WeatherInitial) {
      bloc.add(const FetchWeatherByLocation());
    }
  }

  void _onSettingsChanged() => setState(() {});

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Stack(
        children: [
          BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              if (state is WeatherLoading) return _buildLoadingState();
              if (state is WeatherError) return _buildErrorState(state);

              final loaded = state is WeatherLoaded ? state : null;
              final refreshing = state is WeatherRefreshing ? state : null;

              if (loaded == null && refreshing == null) {
                return _buildInitialState();
              }

              final weather = loaded?.weather ?? refreshing!.weather;
              final airQuality = loaded?.airQuality ?? refreshing?.airQuality;
              final cityName = loaded?.cityName ?? refreshing!.cityName;
              final countryCode = loaded?.countryCode ?? '';
              final stateName = loaded?.stateName ?? refreshing!.stateName;
              final provinceName = loaded?.provinceName ?? refreshing?.provinceName;
              final isRefreshing = state is WeatherRefreshing;

              final current = weather.current;
              final weatherCode = current?.weatherCode ?? 0;
              final isDay = (current?.isDay ?? 1) == 1;
              final gradient =
                  WeatherUtils.getWeatherGradient(weatherCode, isDay: isDay);
              final settings = _settingsController.settings;

              const textColor = AppColors.white;
              const subColor = AppColors.white80;

              return Container(
                decoration: BoxDecoration(gradient: gradient),
                child: SafeArea(
                  // Fix: include bottom in SafeArea so content is never clipped
                  // by the nav bar inset; the bottom SizedBox(height:110) handles spacing.
                  bottom: true,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<WeatherBloc>().add(const RefreshWeather());
                      await Future<void>.delayed(const Duration(seconds: 1));
                    },
                    color: AppColors.tempYellow,
                    backgroundColor: AppColors.primaryDark,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(
                            cityName,
                            countryCode,
                            stateName,
                            provinceName,
                            isRefreshing,
                            textColor: textColor,
                            subColor: subColor,
                          ),
                        ),
                        if (current != null) ...[
                          SliverToBoxAdapter(
                            child: CurrentWeatherCard(
                              current: current,
                              cityName: cityName,
                              weatherCode: weatherCode,
                              isDay: isDay,
                              settings: settings,
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.15),
                          ),
                          if (weather.hourly != null)
                            SliverToBoxAdapter(
                              child: HourlyForecastWidget(
                                hourlyData: weather.hourly!,
                                settings: settings,
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 80.ms),
                            ),
                          SliverToBoxAdapter(
                            child: WeatherDetailsGrid(
                              current: current,
                              settings: settings,
                            ).animate().fadeIn(duration: 500.ms, delay: 160.ms),
                          ),
                          if (airQuality != null && settings.showAQI)
                            SliverToBoxAdapter(
                              child: AirQualityCard(airQuality: airQuality)
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 240.ms),
                            ),
                          if (weather.daily != null)
                            SliverToBoxAdapter(
                              // Fix: wrap DailyForecastWidget in a horizontally
                              // constrained box so the temp-bar Row never overflows
                              // to the right.
                              child: LayoutBuilder(
                                builder: (context, constraints) => SizedBox(
                                  width: constraints.maxWidth,
                                  child: DailyForecastWidget(
                                    dailyData: weather.daily!,
                                    settings: settings,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 320.ms),
                            ),
                        ],
                        // Extra bottom spacing so content clears the nav bar
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showSearch)
            SearchOverlay(
              onClose: () => setState(() => _showSearch = false),
              onLocationSelected: (result) {
                setState(() => _showSearch = false);
                context.read<WeatherBloc>().add(
                      FetchWeatherByCoords(
                        lat: result.lat,
                        lon: result.lon,
                        cityName: result.name,
                        countryCode: result.country,
                        stateName: result.state,
                        provinceName: result.admin2,
                      ),
                    );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String cityName,
    String country,
    String stateName,
    String? provinceName,
    bool isRefreshing, {
    required Color textColor,
    required Color subColor,
  }) {
    final cityLabel = provinceName != null && provinceName.trim().isNotEmpty
        ? '$cityName, $provinceName'
        : cityName;
    final locationDetail = country.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          // Fix: Expanded prevents the city label row from overflowing right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: subColor.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                // Fix: use Wrap instead of Row so badge + spinner never
                // push past the right edge of the screen.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.tempYellow,
                      size: 17,
                    ),
                    // City name — constrain width so it doesn't crowd the badge
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 160,
                      ),
                      child: Text(
                        cityLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (locationDetail.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          locationDetail,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11,
                            color: subColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    if (isRefreshing)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: subColor.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: Icons.search_rounded,
            onTap: () => setState(() => _showSearch = true),
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: Icons.my_location_rounded,
            onTap: () =>
                context.read<WeatherBloc>().add(const FetchWeatherByLocation()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.skyGradient),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: AppColors.tempYellow,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 28),
            Text(
              'ATMOS',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 10,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fetching weather data…',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 14,
                color: AppColors.white60,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WeatherError state) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.skyGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.white60,
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Unable to fetch weather',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  color: AppColors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<WeatherBloc>()
                    .add(const FetchWeatherByLocation()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.skyGradient),
      child: const Center(
        child: Text(
          'ATMOS',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 14,
          ),
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}