import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../platform/file_entry.dart';
import 'async_semaphore.dart';

abstract class IThumbnailProvider {
  Future<Uint8List> getThumbnail(FileEntry entry);
}

class ThumbnailProvider implements IThumbnailProvider {

  ThumbnailProvider({
    required this.cacheDir,
    this.thumbSize = 160,
    int maxConcurrent = 4,
  }) : semaphore = AsyncSemaphore(maxConcurrent),
       _cacheManager = CacheManager(
         Config(
           'thumbCache',
           stalePeriod: const Duration(days: 7),
           maxNrOfCacheObjects: 20000,
         ),
       );
  final Directory cacheDir;
  final int thumbSize;
  final AsyncSemaphore semaphore;
  final CacheManager _cacheManager;

  @override
  Future<Uint8List> getThumbnail(FileEntry entry) async {
    // Isolate/computeは使わず、メインスレッドでサムネイル生成・キャッシュ
    return semaphore.run(() async {
      final String thumbPath = entry.getThumbnailPath(cacheDir);
      final FileInfo? cached = await _cacheManager.getFileFromCache(thumbPath);
      if (cached != null && await cached.file.exists()) {
        log('Thumbnail loaded from cache: $thumbPath');
        return cached.file.readAsBytes();
      }
      log('Thumbnail generated and cached: $thumbPath');
      final Uint8List bytes = await entry.thumbnailReadAsBytes(cacheDir, size: thumbSize);
      await _cacheManager.putFile(thumbPath, bytes);
      log('Thumbnail saved to cache: $thumbPath');
      return bytes;
    });
  }
}
