import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../infrastructure/setting.dart';

class ThumbnailConfig {
  const ThumbnailConfig({
    required this.stalePeriodDays,
    required this.maxDiskThumbnailCount,
    required this.thumbnailDirectoryPath,
  });

  final int stalePeriodDays;
  final int maxDiskThumbnailCount;
  final String thumbnailDirectoryPath;

  ThumbnailConfig copyWith({
    int? stalePeriodDays,
    int? maxDiskThumbnailCount,
    String? thumbnailDirectoryPath,
  }) => ThumbnailConfig(
    stalePeriodDays: stalePeriodDays ?? this.stalePeriodDays,
    maxDiskThumbnailCount: maxDiskThumbnailCount ?? this.maxDiskThumbnailCount,
    thumbnailDirectoryPath: thumbnailDirectoryPath ?? this.thumbnailDirectoryPath,
  );

  Directory get thumbnailDirectory {
    return Directory(thumbnailDirectoryPath);
  }
}

class ThumbnailConfigNotifier extends StateNotifier<ThumbnailConfig> {
  ThumbnailConfigNotifier()
    : super(
        const ThumbnailConfig(
          stalePeriodDays: SettingDefaults.stalePeriodDays,
          maxDiskThumbnailCount: SettingDefaults.maxDiskThumbnailCount,
          thumbnailDirectoryPath: SettingDefaults.thumbnailDirectoryPath,
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final int stalePeriodDays = await settingsStorage.getInt(
      Settings.stalePeriodDays,
      SettingDefaults.stalePeriodDays,
    );
    final int maxDiskThumbnailCount = await settingsStorage.getInt(
      Settings.maxDiskThumbnailCount,
      SettingDefaults.maxDiskThumbnailCount,
    );
    final Directory cacheDir = await getTemporaryDirectory();
    final String thumbnailDirectoryPath = await settingsStorage.getString(
      Settings.thumbnailDirectoryPath,
      cacheDir.path,
    );

    state = ThumbnailConfig(
      stalePeriodDays: stalePeriodDays,
      maxDiskThumbnailCount: maxDiskThumbnailCount,
      thumbnailDirectoryPath: thumbnailDirectoryPath,
    );
  }

  Future<void> setStalePeriodDays(int stalePeriodDays) async {
    state = state.copyWith(stalePeriodDays: stalePeriodDays);
    await settingsStorage.setInt(Settings.stalePeriodDays, stalePeriodDays);
  }

  Future<void> setMaxDiskThumbnailCount(int maxDiskThumbnailCount) async {
    state = state.copyWith(maxDiskThumbnailCount: maxDiskThumbnailCount);
    await settingsStorage.setInt(Settings.maxDiskThumbnailCount, maxDiskThumbnailCount);
  }

  Future<void> loadFromStorage() async {
    await _load();
  }
}

final StateNotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig> thumbnailConfigProvider =
    StateNotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig>(
      (StateNotifierProviderRef<ThumbnailConfigNotifier, ThumbnailConfig> ref) =>
          ThumbnailConfigNotifier(),
    );
