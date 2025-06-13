import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mygallery/platform/file_entry.dart';
import 'package:mygallery/platform/file_entry_windows.dart';
import 'package:mygallery/platform/image_service.dart';
import 'dart:io';

class WindowsImageService extends ImageService with ImageServiceImpl {
  @override
  Future<List<String>> getImages(String directoryPath) {
    // Windows用の画像取得ロジックを実装
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return Future.value([]);
    }
    final files = directory.list();
    final imageFiles =
        files
            .where((file) {
              final name = file.path.toLowerCase();
              return name.endsWith('.jpg') ||
                  name.endsWith('.jpeg') ||
                  name.endsWith('.png') ||
                  name.endsWith('.gif') ||
                  name.endsWith('.webp');
            })
            .map((f) => f.path)
            .toList();
    return Future.value(imageFiles);
  }

  @override
  Future<FileEntry?> pickDirectoryPath() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return null;
    }
    // FilePickerで取得したパスをFileSystemEntityに変換
    final directory = Directory(directoryPath);

    return IOFileEntry(directory);
  }

  @override
  Future<Uint8List> getImageByte(String imagePath) async {
    // Windows用の画像バイト取得ロジックを実装
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $imagePath');
    }
    return await file.readAsBytes();
  }

  @override
  Future<Uint8List> getThumbnailBytes(
    String imagePath, {
    int size = 128,
  }) async {
    final thumbnailPath = getThumbnailPath(imagePath);
    final thumbnailByte = File(thumbnailPath);
    if (thumbnailByte.existsSync()) {
      return await thumbnailByte.readAsBytes();
    }

    final bytes = await getImageByte(imagePath);
    if (bytes.isEmpty) {
      throw Exception('画像の読み込みに失敗しました: $imagePath');
    }

    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('画像のデコードに失敗しました');

    final thumbnail = img.copyResize(image, width: size);
    return Uint8List.fromList(img.encodeJpg(thumbnail));
  }
}
