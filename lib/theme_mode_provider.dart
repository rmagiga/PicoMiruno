import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (StateNotifierProviderRef<ThemeModeNotifier, ThemeMode> ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mode = prefs.getString('theme_mode');
    if (mode == 'light') {
      state = ThemeMode.light;
    } else if (mode == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      prefs.setString('theme_mode', 'light');
    } else if (mode == ThemeMode.dark) {
      prefs.setString('theme_mode', 'dark');
    } else {
      prefs.setString('theme_mode', 'system');
    }
  }

  Future<void> loadFromStorage() async {
    await _loadThemeMode();
  }
}
