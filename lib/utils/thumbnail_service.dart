import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../platform/file_entry.dart';
import 'app_logger.dart';
import 'async_semaphore.dart';

abstract class IThumbnailService {
  Future<Uint8List> getThumbnail(FileEntry entry);
}

class ThumbnailService implements IThumbnailService {
  ThumbnailService({
    required this.cacheDir,
    required this.thumbSize,
    required this.cacheManager,
    int maxConcurrent = 4,
  }) : semaphore = AsyncSemaphore(maxConcurrent);
  final Directory cacheDir;
  final int thumbSize;
  final AsyncSemaphore semaphore;
  final CacheManager cacheManager;

  @override
  Future<Uint8List> getThumbnail(FileEntry entry) async {
    // Isolate/computeは使わず、メインスレッドでサムネイル生成・キャッシュ
    return semaphore.run(() async {
      final String thumbPath = entry.getThumbnailPath(cacheDir);
      final FileInfo? cached = await cacheManager.getFileFromCache(thumbPath);
      if (cached != null && await cached.file.exists()) {
        logger.d('サムネイルをキャッシュから読み込みました: $thumbPath');
        return cached.file.readAsBytes();
      }
      final Uint8List bytes = await entry.thumbnailReadAsBytes(cacheDir, size: thumbSize);
      await cacheManager.putFile(thumbPath, bytes);
      logger.d('サムネイルをキャッシュに保存しました: $thumbPath');
      return bytes;
    });
  }
}
