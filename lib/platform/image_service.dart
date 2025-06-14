import 'dart:io';
import 'dart:typed_data';
import 'package:mygallery/platform/image_service_android.dart';
import 'package:mygallery/platform/image_service_windows.dart';
import 'file_entry.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

abstract class ImageService {
  Future<FileEntry?> pickDirectoryPath();
  Future<List<String>> getImages(String directoryPath);
  Future<Uint8List> getImageByte(String imagePath);
  Future<Uint8List> getThumbnailBytes(String imagePath, {int size = 128});
}

mixin ImageServiceImpl {
  // プラットフォームごとにキャッシュ数・容量を切り替え
  int get maxDiskThumbnailCount {
    if (Platform.isAndroid) return 5000;
    if (Platform.isWindows) return 20000;
    return 5000;
  }

  int get maxDiskThumbnailBytes {
    if (Platform.isAndroid) return 200 * 1024 * 1024; // 200MB
    if (Platform.isWindows) return 500 * 1024 * 1024; // 500MB
    return 200 * 1024 * 1024;
  }

  Future<String> getThumbnailPath(String imagePath) async {
    final cacheDir = await getTemporaryDirectory();
    return '${cacheDir.path}/${imagePath.hashCode}_thumb.jpg';
  }

  // サムネイル生成関数
  Future<Uint8List> _generateThumbnail(
    String imagePath, {
    int size = 128,
  }) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('画像のデコードに失敗しました');
    final thumbnail = img.copyResize(image, width: size);
    return Uint8List.fromList(img.encodeJpg(thumbnail));
  }

  Future<String> cacheThumbnail(String imagePath) async {
    final cacheDir = await getTemporaryDirectory();
    final thumbPath = '${cacheDir.path}/${imagePath.hashCode}_thumb.jpg';

    if (!File(thumbPath).existsSync()) {
      final thumbBytes = await _generateThumbnail(imagePath);
      await File(thumbPath).writeAsBytes(thumbBytes);
      await _cleanupOldThumbnails(cacheDir);
    }
    return thumbPath;
  }

  // ディスクキャッシュのサムネイル数を制限
  Future<void> _cleanupOldThumbnails(Directory cacheDir) async {
    final files =
        cacheDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('_thumb.jpg'))
            .toList();

    // ファイル数制限
    if (files.length > maxDiskThumbnailCount) {
      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      final removeCount = files.length - maxDiskThumbnailCount;
      for (int i = 0; i < removeCount; i++) {
        try {
          files[i].deleteSync();
        } catch (_) {}
      }
    }

    // 合計サイズ制限
    int totalSize = files.fold(0, (sum, f) => sum + f.statSync().size);
    if (totalSize > maxDiskThumbnailBytes) {
      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (final file in files) {
        if (totalSize <= maxDiskThumbnailBytes) break;
        try {
          totalSize -= file.statSync().size;
          file.deleteSync();
        } catch (_) {}
      }
    }
  }
}

class ImageServiceFactory {
  static ImageService create() {
    // ここでプラットフォームに応じたImageServiceの実装を返す
    if (Platform.isAndroid) {
      return AndroidImageService();
    } else if (Platform.isWindows) {
      return WindowsImageService();
    }

    // 今回は仮の実装としてnullを返します。
    throw UnimplementedError('ImageServiceの実装が必要です');
  }
}
