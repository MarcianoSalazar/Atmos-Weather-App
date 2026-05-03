// lib/core/utils/settings_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/weather_model.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._();

  static final SettingsController instance = SettingsController._();

  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    await _reload();
  }

  Future<void> reload() async {
    await _reload();
  }

  Future<void> update(AppSettings updated) async {
    _settings = updated;
    _loaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.settingsKey,
      jsonEncode(updated.toJson()),
    );
  }

  Future<void> _reload() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.settingsKey);
    if (stored != null) {
      try {
        _settings =
            AppSettings.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      } catch (_) {
        _settings = AppSettings();
      }
    }
    _loaded = true;
    notifyListeners();
  }
}
