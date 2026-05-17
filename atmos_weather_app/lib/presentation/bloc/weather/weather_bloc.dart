// lib/presentation/bloc/weather/weather_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:atmos/data/models/weather_model.dart';
import 'package:atmos/data/repositories/weather_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  @override
  List<Object?> get props => [];
}

class FetchWeatherByLocation extends WeatherEvent {
  const FetchWeatherByLocation();
}

class FetchWeatherByCoords extends WeatherEvent {
  final double lat;
  final double lon;
  final String? cityName;
  final String? countryCode;
  final String? stateName;
  final String? provinceName; // admin2 — province/district level
  const FetchWeatherByCoords({
    required this.lat,
    required this.lon,
    this.cityName,
    this.countryCode,
    this.stateName,
    this.provinceName,
  });
  @override
  List<Object?> get props =>
      [lat, lon, cityName, countryCode, stateName, provinceName];
}

class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}

class SearchCity extends WeatherEvent {
  final String query;
  const SearchCity(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearSearch extends WeatherEvent {
  const ClearSearch();
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherRefreshing extends WeatherState {
  final OpenMeteoModel weather;
  final AirQualityModel? airQuality;
  final String cityName;
  final String countryCode;
  final String stateName;
  final String? provinceName; // admin2 — province/district level
  final double lat;
  final double lon;
  const WeatherRefreshing({
    required this.weather,
    this.airQuality,
    required this.cityName,
    required this.countryCode,
    required this.stateName,
    this.provinceName,
    required this.lat,
    required this.lon,
  });
  @override
  List<Object?> get props => [
        weather,
        airQuality,
        cityName,
        countryCode,
        stateName,
        provinceName,
        lat,
        lon
      ];
}

class WeatherLoaded extends WeatherState {
  final OpenMeteoModel weather;
  final AirQualityModel? airQuality;
  final String cityName;
  final String countryCode;
  final String stateName;
  final String? provinceName; // admin2 — province/district level
  final double lat;
  final double lon;
  final DateTime lastUpdated;
  const WeatherLoaded({
    required this.weather,
    this.airQuality,
    required this.cityName,
    required this.countryCode,
    required this.stateName,
    this.provinceName,
    required this.lat,
    required this.lon,
    required this.lastUpdated,
  });
  @override
  List<Object?> get props => [
        weather,
        airQuality,
        cityName,
        countryCode,
        stateName,
        provinceName,
        lat,
        lon,
        lastUpdated,
      ];
}

class WeatherError extends WeatherState {
  final String message;
  const WeatherError({required this.message});
  @override
  List<Object?> get props => [message];
}

class SearchLoading extends WeatherState {
  const SearchLoading();
}

class SearchLoaded extends WeatherState {
  final List<GeocodingResult> results;
  final String query;
  const SearchLoaded({required this.results, required this.query});
  @override
  List<Object?> get props => [results, query];
}

class SearchEmpty extends WeatherState {
  final String query;
  const SearchEmpty({required this.query});
  @override
  List<Object?> get props => [query];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _repository;

  double? _currentLat;
  double? _currentLon;
  String _currentCity = '';
  String _currentCountry = '';
  String _currentState = '';
  String? _currentProvince; // admin2

  WeatherBloc({required WeatherRepository repository})
      : _repository = repository,
        super(const WeatherInitial()) {
    on<FetchWeatherByLocation>(_onFetchByLocation);
    on<FetchWeatherByCoords>(_onFetchByCoords);
    on<RefreshWeather>(_onRefresh);
    on<SearchCity>(_onSearchCity);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onFetchByLocation(
    FetchWeatherByLocation event,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());
    try {
      final position = await _determinePosition();
      _currentLat = position.latitude;
      _currentLon = position.longitude;

      final geo = await _repository.reverseGeocode(
        lat: _currentLat!,
        lon: _currentLon!,
      );
      _currentCity = geo?.name ?? 'Your Location';
      _currentCountry = geo?.country ?? '';
      _currentState = geo?.state ?? '';
      _currentProvince = geo?.admin2;

      await _repository.addRecentLocation(
        GeocodingResult(
          name: _currentCity,
          lat: _currentLat!,
          lon: _currentLon!,
          country: _currentCountry,
          state: _currentState,
          admin2: _currentProvince,
        ),
      );

      await _fetchAndEmit(emit);
    } catch (_) {
      emit(
        const WeatherError(
          message: 'Unable to get current location. Please enable GPS.',
        ),
      );
    }
  }

  Future<void> _onFetchByCoords(
    FetchWeatherByCoords event,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());
    _currentLat = event.lat;
    _currentLon = event.lon;
    _currentCity = event.cityName ?? _currentCity;
    _currentCountry = event.countryCode ?? _currentCountry;
    _currentState = (event.stateName ?? '').trim();
    _currentProvince = event.provinceName?.trim().isEmpty == true
        ? null
        : event.provinceName?.trim();

    await _repository.addRecentLocation(
      GeocodingResult(
        name: _currentCity.isNotEmpty ? _currentCity : 'Selected Location',
        lat: _currentLat!,
        lon: _currentLon!,
        country: _currentCountry,
        state: _currentState,
        admin2: _currentProvince,
      ),
    );
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (_currentLat == null || _currentLon == null) {
      add(const FetchWeatherByLocation());
      return;
    }
    final current = state;
    if (current is WeatherLoaded) {
      emit(
        WeatherRefreshing(
          weather: current.weather,
          airQuality: current.airQuality,
          cityName: current.cityName,
          countryCode: current.countryCode,
          stateName: current.stateName,
          provinceName: current.provinceName,
          lat: current.lat,
          lon: current.lon,
        ),
      );
    }
    await _fetchAndEmit(emit);
  }

  Future<void> _onSearchCity(
    SearchCity event,
    Emitter<WeatherState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const WeatherInitial());
      return;
    }
    emit(const SearchLoading());
    try {
      final results = await _repository.searchLocations(event.query.trim());
      if (results.isEmpty) {
        emit(SearchEmpty(query: event.query));
      } else {
        emit(SearchLoaded(results: results, query: event.query));
      }
    } catch (_) {
      emit(SearchEmpty(query: event.query));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<WeatherState> emit) {
    if (_currentLat != null) {
      add(const RefreshWeather());
    } else {
      emit(const WeatherInitial());
    }
  }

  Future<void> _fetchAndEmit(Emitter<WeatherState> emit) async {
    try {
      final lat = _currentLat!;
      final lon = _currentLon!;

      final results = await Future.wait([
        _repository.fetchOpenMeteoForecast(lat: lat, lon: lon),
        _repository.fetchAirQuality(lat: lat, lon: lon),
      ]);

      final weather = results[0] as OpenMeteoModel;
      final airQuality = results[1] as AirQualityModel?;

      emit(
        WeatherLoaded(
          weather: weather,
          airQuality: airQuality,
          cityName: _currentCity.isNotEmpty ? _currentCity : 'Your Location',
          countryCode: _currentCountry,
          stateName: _currentState,
          provinceName: _currentProvince,
          lat: lat,
          lon: lon,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(WeatherError(message: e.toString()));
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 12),
    );
  }
}
