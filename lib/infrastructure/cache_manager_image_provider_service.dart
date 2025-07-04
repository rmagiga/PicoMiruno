import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../platform/file_entry.dart';
import 'image_provider_service.dart';

/// flutter_cache_managerを使った実装（SRP, OCP）
class CacheManagerImageProviderService implements ImageProviderService {
  CacheManagerImageProviderService({DefaultCacheManager? cacheManager})
    : cacheManager = cacheManager ?? DefaultCacheManager();
  final DefaultCacheManager cacheManager;

  @override
  Future<Uint8List> getImageBytes(FileEntry fileEntry) async {
    final String imagePath = fileEntry.path;
    final FileInfo? cachedFile = await cacheManager.getFileFromCache(imagePath);
    if (cachedFile != null && await cachedFile.file.exists()) {
      return cachedFile.file.readAsBytes();
    }
    final Uint8List bytes = await fileEntry.readAsBytes();
    await cacheManager.putFile(imagePath, bytes);
    return bytes;
  }
}
