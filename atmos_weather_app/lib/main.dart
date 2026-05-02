// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/weather_repository.dart';
import 'presentation/bloc/weather/weather_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ),);

  // Initialize dependencies
  final prefs = await SharedPreferences.getInstance();
  final dio = _createDio();
  final weatherRepository = WeatherRepository(dio: dio, prefs: prefs);

  runApp(AtmosApp(weatherRepository: weatherRepository));
}

Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Add logging interceptor in debug
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('Dio error: ${error.message}');
        handler.next(error);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
    ),
  );

  return dio;
}

class AtmosApp extends StatelessWidget {
  final WeatherRepository weatherRepository;

  const AtmosApp({super.key, required this.weatherRepository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<WeatherRepository>(
      create: (_) => weatherRepository,
      child: BlocProvider<WeatherBloc>(
        create: (context) => WeatherBloc(
          repository: context.read<WeatherRepository>(),
        ),
        child: MaterialApp(
          title: 'ATMOS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
