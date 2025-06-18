import 'dart:typed_data';

import 'package:docman/docman.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'package:mygallery/platform/file_entry_android.dart';

import 'image_service.dart';

class AndroidImageService extends ImageService with ImageServiceImpl {
  @override
  Future<FileEntry?> pickDirectoryPath() async {
    // Android用のフォルダ選択ロジックを実装
    var documentFile = await DocMan.pick.directory();
    if (documentFile != null) {
      return DocumentFileEntry(documentFile);
    }

    return null;
  }

  @override
  Future<List<String>> getImages(String directoryPath) async {
    // Android用の画像取得ロジックを実装
    final docFolder = await DocumentFile.fromUri(directoryPath);
    if (docFolder == null) return [];

    final files = await docFolder.listDocuments();
    final imageFiles =
        files
            .where((f) {
              final name = f.name.toLowerCase();
              return name.endsWith('.jpg') ||
                  name.endsWith('.jpeg') ||
                  name.endsWith('.png') ||
                  name.endsWith('.gif') ||
                  name.endsWith('.webp');
            })
            .map((f) => f.uri.toString())
            .toList();

    return imageFiles;
  }

  @override
  Future<Uint8List> getImageByte(String imagePath) async {
    final documentFile = await DocumentFile.fromUri(imagePath);

    return _getImageByte(imagePath, documentFile);
  }

  Future<Uint8List> _getImageByte(
    String imagePath,
    DocumentFile? documentFile,
  ) async {
    if (documentFile == null) {
      throw Exception('Document file not found: $imagePath');
    }
    final bytes = await documentFile.read();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('画像の読み込みに失敗しました: $imagePath');
    }
    return bytes;
  }

  @override
  Future<Uint8List> getThumbnailBytes(
    String imagePath, {
    int size = 128,
  }) async {
    final documentFile = await DocumentFile.fromUri(imagePath);
    if (documentFile == null) {
      throw Exception('Document file not found: $imagePath');
    }
    if (documentFile.canThumbnail) {
      final documentThumbnail = await documentFile.thumbnail(
        height: size,
        width: size,
      );
      if (documentThumbnail != null) {
        return documentThumbnail.bytes;
      }
    }
    return _getImageByte(imagePath, documentFile);
  }
}
