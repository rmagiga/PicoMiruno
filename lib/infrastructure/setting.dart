import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsStorage {
  Future<String> getString(String key, String defaultValue);

  Future<void> setString(String key, String value);

  Future<int> getInt(String key, int defaultValue);

  Future<void> setInt(String key, int value);
}

class SharedPreferencesSettingsStorage implements SettingsStorage {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<String> getString(String key, String defaultValue) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(key) ?? defaultValue;
  }

  @override
  Future<void> setString(String key, String value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(key, value);
  }

  @override
  Future<int> getInt(String key, int defaultValue) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getInt(key) ?? defaultValue;
  }

  @override
  Future<void> setInt(String key, int value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setInt(key, value);
  }
}

final SettingsStorage settingsStorage = SharedPreferencesSettingsStorage();
