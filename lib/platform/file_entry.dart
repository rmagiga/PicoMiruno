// abstract_file_entry.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:mygallery/platform/file_entry_android.dart';
import 'package:mygallery/platform/file_entry_windows.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

const List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

abstract class FileEntry {
  String get name;
  String get path;
  Future<Uint8List> readAsBytes();
  Future<String> getThumbnailPath();
  Future<Uint8List> thumbnailReadAsBytes({int size = 128});
}

mixin ThumbnailMixin on FileEntry {
  @override
  Future<String> getThumbnailPath() async {
    // サムネイルのパスを生成
    final cacheDir = await getTemporaryDirectory();
    return '${cacheDir.path}/${path.hashCode}_thumb.jpg';
  }

  @override
  Future<Uint8List> thumbnailReadAsBytes({int size = 128}) async {
    final thumbPath = await getThumbnailPath();
    final thumbFile = File(thumbPath);

    // サムネイルが存在しない場合は生成
    if (!thumbFile.existsSync()) {
      final bytes = await readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('画像のデコードに失敗しました');
      final thumbnail = img.copyResize(image, width: size, height: size);
      await thumbFile.writeAsBytes(img.encodeJpg(thumbnail));
    }

    return await thumbFile.readAsBytes();
  }
}

abstract class DirectoryEntry {
  String get name;
  String get path;
  Future<List<FileEntry>> listFiles();
}

abstract class DirectoryEntryFactory {
  DirectoryEntry create(String path);
  Future<DirectoryEntry?> pickDirectory();

  factory DirectoryEntryFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return DocumentFileDirectoryEntryFactory();
    } else {
      return IOFileDirectoryEntryFactory();
    }
  }
}
