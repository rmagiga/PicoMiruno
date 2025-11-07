import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../infrastructure/setting.dart';

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system;
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
