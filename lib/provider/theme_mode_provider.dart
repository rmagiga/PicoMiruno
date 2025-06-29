import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../infrastructure/setting.dart';

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
      (StateNotifierProviderRef<ThemeModeNotifier, ThemeMode> ref) => ThemeModeNotifier(),
    );

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final String mode = await settingsStorage.getString(Settings.themeMode, ThemeMode.system.name);
    if (mode == ThemeMode.light.name) {
      state = ThemeMode.light;
    } else if (mode == ThemeMode.dark.name) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await settingsStorage.setString(Settings.themeMode, mode.name);
  }

  Future<void> loadFromStorage() async {
    await _loadThemeMode();
  }
}
