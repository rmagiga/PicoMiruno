import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../infrastructure/setting.dart';

class ThumbnailConfig {
  const ThumbnailConfig({required this.stalePeriodDays, required this.maxDiskThumbnailCount});

  final int stalePeriodDays;
  final int maxDiskThumbnailCount;

  ThumbnailConfig copyWith({int? stalePeriodDays, int? maxDiskThumbnailCount}) => ThumbnailConfig(
    stalePeriodDays: stalePeriodDays ?? this.stalePeriodDays,
    maxDiskThumbnailCount: maxDiskThumbnailCount ?? this.maxDiskThumbnailCount,
  );
}

final NotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig> thumbnailConfigProvider =
    NotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig>(ThumbnailConfigNotifier.new);

class ThumbnailConfigNotifier extends Notifier<ThumbnailConfig> {
  @override
  ThumbnailConfig build() {
    return const ThumbnailConfig(
      stalePeriodDays: SettingDefaults.stalePeriodDays,
      maxDiskThumbnailCount: SettingDefaults.maxDiskThumbnailCount,
    );
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
    state = ThumbnailConfig(
      stalePeriodDays: stalePeriodDays,
      maxDiskThumbnailCount: maxDiskThumbnailCount,
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
