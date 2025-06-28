import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThumbnailConfig {
  const ThumbnailConfig({required this.maxCount, required this.maxBytes});
  final int maxCount;
  final int maxBytes;

  ThumbnailConfig copyWith({int? maxCount, int? maxBytes}) => ThumbnailConfig(
    maxCount: maxCount ?? this.maxCount,
    maxBytes: maxBytes ?? this.maxBytes,
  );
}

final StateNotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig> thumbnailConfigProvider =
    StateNotifierProvider<ThumbnailConfigNotifier, ThumbnailConfig>(
      (StateNotifierProviderRef<ThumbnailConfigNotifier, ThumbnailConfig> ref) => ThumbnailConfigNotifier(),
    );

class ThumbnailConfigNotifier extends StateNotifier<ThumbnailConfig> {
  ThumbnailConfigNotifier()
    : super(
        const ThumbnailConfig(maxCount: 5000, maxBytes: 200 * 1024 * 1024),
      ) {
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt('maxDiskThumbnailCount') ?? 5000;
    final int bytes = prefs.getInt('maxDiskThumbnailBytes') ?? 200 * 1024 * 1024;
    state = ThumbnailConfig(maxCount: count, maxBytes: bytes);
  }

  Future<void> setMaxCount(int count) async {
    state = state.copyWith(maxCount: count);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxDiskThumbnailCount', count);
  }

  Future<void> setMaxBytes(int bytes) async {
    state = state.copyWith(maxBytes: bytes);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxDiskThumbnailBytes', bytes);
  }

  Future<void> loadFromStorage() async {
    await _load();
  }
}
