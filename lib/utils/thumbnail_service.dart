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
    required this.stalePeriodDays,
    required this.maxNrOfCacheObjects,
    int maxConcurrent = 4,
  }) : semaphore = AsyncSemaphore(maxConcurrent),
       _cacheManager = CacheManager(
         Config(
           'thumbCache',
           stalePeriod: Duration(days: stalePeriodDays),
           maxNrOfCacheObjects: maxNrOfCacheObjects,
         ),
       );
  final Directory cacheDir;
  final int thumbSize;
  final int stalePeriodDays;
  final int maxNrOfCacheObjects;
  final AsyncSemaphore semaphore;
  final CacheManager _cacheManager;

  @override
  Future<Uint8List> getThumbnail(FileEntry entry) async {
    // Isolate/computeは使わず、メインスレッドでサムネイル生成・キャッシュ
    return semaphore.run(() async {
      final String thumbPath = entry.getThumbnailPath(cacheDir);
      final FileInfo? cached = await _cacheManager.getFileFromCache(thumbPath);
      if (cached != null && await cached.file.exists()) {
        logger.d('Thumbnail loaded from cache: $thumbPath');
        return cached.file.readAsBytes();
      }
      final Uint8List bytes = await entry.thumbnailReadAsBytes(cacheDir, size: thumbSize);
      await _cacheManager.putFile(thumbPath, bytes);
      logger.d('Thumbnail saved to cache: $thumbPath');
      return bytes;
    });
  }
}
