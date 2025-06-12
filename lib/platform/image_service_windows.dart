import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'package:mygallery/platform/file_entry_windows.dart';
import 'package:mygallery/platform/image_service.dart';
import 'dart:io';

class WindowsImageService implements ImageService {
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
  Future<Image> getImage(String imagePath) async {
    // Windows用の画像取得ロジックを実装
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $imagePath');
    }
    return Image.file(file, fit: BoxFit.cover);
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
