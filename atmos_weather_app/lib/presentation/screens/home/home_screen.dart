// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../bloc/weather/weather_bloc.dart';
import '../../widgets/weather/current_weather_card.dart';
import '../../widgets/weather/hourly_forecast_widget.dart';
import '../../widgets/weather/daily_forecast_widget.dart';
import '../../widgets/weather/weather_details_grid.dart';
import '../../widgets/weather/air_quality_card.dart';
import '../../widgets/weather/search_overlay.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/settings_controller.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../data/models/weather_model.dart';

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
  void initState() {
    super.initState();
    _settingsController.addListener(_handleSettingsUpdate);
    _settingsController.load();
    final state = context.read<WeatherBloc>().state;
    if (state is WeatherInitial) {
      context.read<WeatherBloc>().add(const FetchWeatherByLocation());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _settingsController.removeListener(_handleSettingsUpdate);
    super.dispose();
  }

  void _handleSettingsUpdate() {
    if (mounted) setState(() {});
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
              if (state is WeatherLoading) {
                return _buildLoadingState();
              }
              if (state is WeatherError) {
                return _buildErrorState(state);
              }
              if (state is WeatherLoaded || state is WeatherRefreshing) {
                final loaded = state is WeatherLoaded ? state : null;
                final refreshing = state is WeatherRefreshing ? state : null;
                final weather = loaded?.weather ?? refreshing!.weather;
                final airQuality = loaded?.airQuality ?? refreshing?.airQuality;
                final cityName = loaded?.cityName ?? refreshing!.cityName;
                final country = loaded?.countryCode ?? '';

                return _buildLoadedState(
                  weather: weather,
                  airQuality: airQuality,
                  cityName: cityName,
                  country: country,
                  isRefreshing: state is WeatherRefreshing,
                );
              }
              return _buildInitialState();
            },
          ),

          // Search overlay
          if (_showSearch)
            SearchOverlay(
              onClose: () => setState(() => _showSearch = false),
              onLocationSelected: (result) {
                setState(() => _showSearch = false);
                context.read<WeatherBloc>().add(FetchWeatherByCoords(
                      lat: result.lat,
                      lon: result.lon,
                      cityName: result.name,
                    ));
              },
            ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildLoadedState({
    required OpenMeteoModel weather,
    AirQualityModel? airQuality,
    required String cityName,
    required String country,
    required bool isRefreshing,
  }) {
    final current = weather.current!;
    final isDay = current.isDay == 1;
    final weatherCode = current.weatherCode;
    final gradient = WeatherUtils.getWeatherGradient(weatherCode, isDay: isDay);
    final settings = _settingsController.settings;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
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
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(cityName, country, isRefreshing),
              ),

              // Current Weather
              SliverToBoxAdapter(
                child: CurrentWeatherCard(
                  current: current,
                  cityName: cityName,
                  weatherCode: weatherCode,
                  isDay: isDay,
                  settings: settings,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
              ),

              // Hourly Forecast
              SliverToBoxAdapter(
                child: HourlyForecastWidget(
                  hourlyData: weather.hourly!,
                  settings: settings,
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              ),

              // Weather Details Grid
              SliverToBoxAdapter(
                child: WeatherDetailsGrid(
                  current: current,
                  settings: settings,
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ),

              // Air Quality Card
              if (airQuality != null)
                SliverToBoxAdapter(
                  child: AirQualityCard(
                    airQuality: airQuality,
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                ),

              // Daily Forecast
              SliverToBoxAdapter(
                child: DailyForecastWidget(
                  dailyData: weather.daily!,
                  settings: settings,
                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              ),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String cityName, String country, bool isRefreshing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: AppColors.white60,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.tempYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (country.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.white20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          country,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11,
                            color: AppColors.white80,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (isRefreshing)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white60,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              _HeaderButton(
                icon: Icons.search_rounded,
                onTap: () => setState(() => _showSearch = true),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  context
                      .read<WeatherBloc>()
                      .add(const FetchWeatherByLocation());
                },
              ),
            ],
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
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppColors.tempYellow,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'ATMOS',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fetching weather data...',
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
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.white60, size: 72),
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
                onPressed: () {
                  context
                      .read<WeatherBloc>()
                      .add(const FetchWeatherByLocation());
                },
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
            letterSpacing: 12,
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white20),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
