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
  String getThumbnailPath(String imagePath) {
    final cacheDir = Directory.systemTemp;
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
    }
    return thumbPath;
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
