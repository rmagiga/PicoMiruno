import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'package:mygallery/platform/file_entry_android.dart';
import 'package:mygallery/platform/file_entry_image_provider.dart';

import 'image_service.dart';

class AndroidImageService implements ImageService {
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
  Future<Image> getImage(String imagePath) async {
    // Android用の画像取得ロジックを実装
    final documentFile = await DocumentFile.fromUri(imagePath);
    if (documentFile == null) {
      throw Exception('Document file not found: $imagePath');
    }
    return Image(
      image: FileEntryThumbnailImageProvider(DocumentFileEntry(documentFile)),
      fit: BoxFit.cover,
    );
  }

  Future<Image?> getThumbnailImage(String contentUriOrFilePath) async {
    final documentThumbnail = await DocumentThumbnail.fromUri(
      contentUriOrFilePath,
      width: 192,
      height: 192,
      png: true,
      quality: 100,
    );
    if (documentThumbnail != null) {
      final bytes = documentThumbnail.bytes;
      Image image = Image.memory(bytes);
      return image;
    }
    return null;
  }

  @override
  FutureBuilder<Image> getImageSync(String imagePath) {
    return FutureBuilder<Image>(
      future: getImage(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        } else if (snapshot.hasError) {
          return const Icon(Icons.error, color: Colors.red);
        } else {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
      },
    );
  }
}
