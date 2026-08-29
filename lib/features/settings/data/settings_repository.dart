import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

abstract class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'anniv.settings.v1';

  @override
  AppSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return AppSettings.defaults;
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppSettings settings) =>
      _prefs.setString(_key, jsonEncode(settings.toJson()));
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings seed = AppSettings.defaults])
      : _settings = seed;

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
