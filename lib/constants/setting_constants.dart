class Settings {
  static const String themeMode = 'theme_mode';
  static const String stalePeriodDays = 'stalePeriodDays';
  static const String maxDiskThumbnailCount = 'maxDiskThumbnailCount';
}

class SettingDefaults {
  static const String themeMode = 'system'; // 'light', 'dark', or 'system'
  static const int stalePeriodDays = 7;
  static const int maxDiskThumbnailCount = 20000;
}
