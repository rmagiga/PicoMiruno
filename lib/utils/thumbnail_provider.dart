import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'async_semaphore.dart';

abstract class IThumbnailProvider {
  Future<Uint8List> getThumbnail(FileEntry entry);
}

class ThumbnailProvider implements IThumbnailProvider {
  final Directory cacheDir;
  final int thumbSize;
  final AsyncSemaphore semaphore;
  final CacheManager _cacheManager;

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

  @override
  Future<Uint8List> getThumbnail(FileEntry entry) async {
    // Isolate/computeは使わず、メインスレッドでサムネイル生成・キャッシュ
    return semaphore.run(() async {
      final thumbPath = entry.getThumbnailPath(cacheDir);
      final cached = await _cacheManager.getFileFromCache(thumbPath);
      if (cached != null && await cached.file.exists()) {
        log('Thumbnail loaded from cache: $thumbPath');
        return await cached.file.readAsBytes();
      }
      log('Thumbnail generated and cached: $thumbPath');
      final bytes = await entry.thumbnailReadAsBytes(cacheDir, size: thumbSize);
      await _cacheManager.putFile(thumbPath, bytes);
      log('Thumbnail saved to cache: $thumbPath');
      return bytes;
    });
  }
}
