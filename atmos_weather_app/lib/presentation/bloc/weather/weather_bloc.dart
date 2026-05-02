// lib/presentation/bloc/weather/weather_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/repositories/weather_repository.dart';

// Events
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
  const FetchWeatherByCoords(
      {required this.lat, required this.lon, this.cityName,});
  @override
  List<Object?> get props => [lat, lon, cityName];
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

// States
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
  final double lat;
  final double lon;

  const WeatherRefreshing({
    required this.weather,
    this.airQuality,
    required this.cityName,
    required this.lat,
    required this.lon,
  });

  @override
  List<Object?> get props => [weather, airQuality, cityName, lat, lon];
}

class WeatherLoaded extends WeatherState {
  final OpenMeteoModel weather;
  final AirQualityModel? airQuality;
  final String cityName;
  final String countryCode;
  final double lat;
  final double lon;
  final DateTime lastUpdated;

  const WeatherLoaded({
    required this.weather,
    this.airQuality,
    required this.cityName,
    required this.countryCode,
    required this.lat,
    required this.lon,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props =>
      [weather, airQuality, cityName, countryCode, lat, lon, lastUpdated];
}

class WeatherError extends WeatherState {
  final String message;
  final String? errorCode;
  const WeatherError({required this.message, this.errorCode});
  @override
  List<Object?> get props => [message, errorCode];
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

// BLoC
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _repository;

  double? _currentLat;
  double? _currentLon;
  String _currentCity = 'Unknown';
  String _currentCountry = '';
  bool _usingDeviceLocation = false;

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
      FetchWeatherByLocation event, Emitter<WeatherState> emit,) async {
    emit(const WeatherLoading());
    try {
      final position = await _determinePosition();
      _currentLat = position.latitude;
      _currentLon = position.longitude;
      _usingDeviceLocation = true;

      await _fetchAndEmit(emit);
    } catch (e) {
      // Fallback to default location
      _currentLat = 14.5995;
      _currentLon = 120.9842;
      _currentCity = 'Manila';
      _currentCountry = 'PH';
      _usingDeviceLocation = false;
      await _fetchAndEmit(emit);
    }
  }

  Future<void> _onFetchByCoords(
      FetchWeatherByCoords event, Emitter<WeatherState> emit,) async {
    emit(const WeatherLoading());
    _currentLat = event.lat;
    _currentLon = event.lon;
    _usingDeviceLocation = false;
    if (event.cityName != null) {
      _currentCity = event.cityName!;
    }
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
      RefreshWeather event, Emitter<WeatherState> emit,) async {
    if (_currentLat == null || _currentLon == null) {
      add(const FetchWeatherByLocation());
      return;
    }

    final current = state;
    if (current is WeatherLoaded) {
      emit(WeatherRefreshing(
        weather: current.weather,
        airQuality: current.airQuality,
        cityName: current.cityName,
        lat: current.lat,
        lon: current.lon,
      ),);
    }

    await _fetchAndEmit(emit);
  }

  Future<void> _onSearchCity(
      SearchCity event, Emitter<WeatherState> emit,) async {
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
    } catch (e) {
      emit(SearchEmpty(query: event.query));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<WeatherState> emit) {
    if (_currentLat != null) {
      // Re-emit loaded state if we have data
      add(const RefreshWeather());
    } else {
      emit(const WeatherInitial());
    }
  }

  Future<void> _fetchAndEmit(Emitter<WeatherState> emit) async {
    try {
      final lat = _currentLat!;
      final lon = _currentLon!;

      final futures = await Future.wait([
        _repository.fetchOpenMeteoForecast(lat: lat, lon: lon),
        _repository.fetchAirQuality(lat: lat, lon: lon),
        _repository.searchLocations(
            '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',),
      ]);

      final weather = futures[0] as OpenMeteoModel;
      final airQuality = futures[1] as AirQualityModel?;
      final geoResults = futures[2] as List<GeocodingResult>;

      // Prefer device reverse geocode when using GPS
      if (_usingDeviceLocation) {
        var resolved = await _resolvePlacemark(lat, lon);
        if (resolved.isGeneric) {
          final geo =
              await _repository.reverseGeocodeGeoapify(lat: lat, lon: lon);
          if (geo != null) {
            resolved = _ResolvedLocation(
              displayName: _formatGeoapifyLocation(geo),
              countryCode: geo.country,
              isGeneric: false,
            );
          } else {
            final owm = await _repository.reverseGeocodeOwm(lat: lat, lon: lon);
            if (owm != null) {
              resolved = _ResolvedLocation(
                displayName: _formatOwmLocation(owm),
                countryCode: owm.country,
                isGeneric: false,
              );
            }
          }
        }
        _currentCity = resolved.displayName;
        _currentCountry = resolved.countryCode;
      } else if (geoResults.isNotEmpty && _currentCity == 'Unknown') {
        _currentCity = geoResults.first.name;
        _currentCountry = geoResults.first.country;
      }

      String cityName = _currentCity;
      String country = _currentCountry;

      if (cityName.trim().isEmpty || cityName == 'Unknown') {
        cityName = 'Your Location';
        country = '';
      }

      emit(WeatherLoaded(
        weather: weather,
        airQuality: airQuality,
        cityName: cityName,
        countryCode: country,
        lat: lat,
        lon: lon,
        lastUpdated: DateTime.now(),
      ),);
    } catch (e) {
      emit(WeatherError(message: e.toString()));
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  String _formatOwmLocation(GeocodingResult result) {
    final name = result.name.trim();
    final state = result.state?.trim();
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (state != null && state.isNotEmpty && state != name) parts.add(state);
    return parts.isEmpty ? 'Your Location' : parts.join(', ');
  }

  String _formatGeoapifyLocation(GeocodingResult result) {
    final name = result.name.trim();
    final state = result.state?.trim();
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (state != null && state.isNotEmpty && state != name) parts.add(state);
    return parts.isEmpty ? 'Your Location' : parts.join(', ');
  }

  Future<_ResolvedLocation> _resolvePlacemark(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) {
        return _ResolvedLocation(
          displayName: _formatLatLon(lat, lon),
          countryCode: '',
          isGeneric: true,
        );
      }

      final place = placemarks.first;
      final name = place.name?.trim();
      final street = place.thoroughfare?.trim();
      final subLocality = place.subLocality?.trim();
      final locality = place.locality?.trim();
      final subAdmin = place.subAdministrativeArea?.trim();
      final admin = place.administrativeArea?.trim();

      final parts = <String>[];
      if (name != null && name.isNotEmpty) {
        parts.add(name);
      } else if (street != null && street.isNotEmpty) {
        parts.add(street);
      }
      if (subLocality != null && subLocality.isNotEmpty) {
        final label = subLocality.toLowerCase().startsWith('brgy')
            ? subLocality
            : 'Brgy. $subLocality';
        parts.add(label);
      }

      if (locality != null && locality.isNotEmpty) {
        parts.add(locality);
      } else if (subAdmin != null && subAdmin.isNotEmpty) {
        parts.add(subAdmin);
      }

      if (admin != null && admin.isNotEmpty && !parts.contains(admin)) {
        parts.add(admin);
      }

      final displayName =
          parts.isNotEmpty ? parts.join(', ') : _formatLatLon(lat, lon);

      return _ResolvedLocation(
        displayName: displayName,
        countryCode: place.isoCountryCode ?? place.country ?? '',
        isGeneric: parts.isEmpty,
      );
    } catch (_) {
      return _ResolvedLocation(
        displayName: _formatLatLon(lat, lon),
        countryCode: '',
        isGeneric: true,
      );
    }
  }
}

class _ResolvedLocation {
  final String displayName;
  final String countryCode;
  final bool isGeneric;

  const _ResolvedLocation(
      {required this.displayName,
      required this.countryCode,
      required this.isGeneric,});
}

String _formatLatLon(double lat, double lon) {
  final latStr = lat.toStringAsFixed(4);
  final lonStr = lon.toStringAsFixed(4);
  return '$latStr, $lonStr';
}
