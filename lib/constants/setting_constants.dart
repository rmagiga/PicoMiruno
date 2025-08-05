class Settings {
  static const String themeMode = 'theme_mode';
  static const String stalePeriodDays = 'stalePeriodDays';
  static const String maxDiskThumbnailCount = 'maxDiskThumbnailCount';
  static const String thumbnailDirectoryPath = 'thumbnailDirectoryPath';
}

class SettingDefaults {
  static const String themeMode = 'system'; // 'light', 'dark', or 'system'
  static const int stalePeriodDays = 7;
  static const int maxDiskThumbnailCount = 20000;
  static const String thumbnailDirectoryPath = '.';
}
