// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:atmos/core/theme/app_theme.dart';
import 'package:atmos/core/utils/settings_controller.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/presentation/bloc/weather/weather_bloc.dart';
import 'package:atmos/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080E1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Load settings before app starts
  await SettingsController.instance.load();

  final prefs = await SharedPreferences.getInstance();
  final dio = _buildDio();
  final repo = WeatherRepository(dio: dio, prefs: prefs);

  runApp(AtmosApp(repository: repo));
}

Dio _buildDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (e, h) {
          debugPrint('[Dio] ${e.message}');
          h.next(e);
        },
      ),
    );
}

class AtmosApp extends StatelessWidget {
  final WeatherRepository repository;

  const AtmosApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<WeatherRepository>(
      create: (_) => repository,
      child: BlocProvider<WeatherBloc>(
        create: (ctx) => WeatherBloc(
          repository: ctx.read<WeatherRepository>(),
        ),
        child: MaterialApp(
          title: 'ATMOS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _PermissionGate(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          ),
        ),
      ),
    );
  }
}

/// Shows location + notification permission dialog on first launch,
/// then proceeds to the splash screen — like a real app.
class _PermissionGate extends StatefulWidget {
  const _PermissionGate();

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      if (mounted) setState(() => _done = true);
      return;
    }
    // Only show the dialog if not already decided
    final locationStatus = await Permission.locationWhenInUse.status;
    if (locationStatus.isDenied || locationStatus.isRestricted) {
      if (mounted) await _showLocationDialog();
    }

    // Request location
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    // Request notifications (Android 13+ / iOS)
    final notifStatus = await Permission.notification.status;
    if (notifStatus.isDenied) {
      await Permission.notification.request();
    }

    if (mounted) setState(() => _done = true);
  }

  Future<void> _showLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Allow Location Access',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'ATMOS needs your location to show accurate local weather '
                'forecasts, alerts, and conditions for your area.',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  color: AppColors.white60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We also use notifications to alert you of severe weather events.',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppColors.white40,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Allow Access',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    color: AppColors.white40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      // Show a brief loading screen while permissions resolve
      return const Scaffold(
        backgroundColor: AppColors.primaryDeep,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }
    return const SplashScreen();
  }
}
