// abstract_file_entry.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'file_entry_android.dart';
import 'file_entry_windows.dart';

const List<String> imageExtensions = <String>['.jpg', '.jpeg', '.png', '.gif', '.webp'];

abstract class FileEntry {
  String get name;
  String get path;
  Future<Uint8List> readAsBytes();
  String getThumbnailPath(Directory cacheDir);
  Future<Uint8List> thumbnailReadAsBytes(Directory cacheDir, {int size = 128});
  int getLastModifiedTime();
}

mixin ThumbnailMixin on FileEntry {
  @override
  String getThumbnailPath(Directory cacheDir) {
    // サムネイルのパスを生成
    return '${cacheDir.path}/${path.hashCode}_thumb.jpg';
  }

  @override
  Future<Uint8List> thumbnailReadAsBytes(
    Directory cacheDir, {
    int size = 128,
  }) async {
    final String thumbPath = getThumbnailPath(cacheDir);
    final File thumbFile = File(thumbPath);

    // サムネイルが存在しない場合は生成
    if (!thumbFile.existsSync()) {
      final Uint8List bytes = await readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('画像のデコードに失敗しました');
      }
      final img.Image thumbnail = img.copyResize(image, width: size, height: size);
      await thumbFile.writeAsBytes(img.encodeJpg(thumbnail));
    }

    return thumbFile.readAsBytes();
  }
}

abstract class DirectoryEntry {
  String get name;
  String get path;
  String get viewPath;
  Future<List<FileEntry>> listFiles();
}

abstract class DirectoryEntryFactory {

  factory DirectoryEntryFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return DocumentFileDirectoryEntryFactory();
    } else {
      return IOFileDirectoryEntryFactory();
    }
  }
  Future<DirectoryEntry> create(String path);
  Future<DirectoryEntry?> pickDirectory();
}
