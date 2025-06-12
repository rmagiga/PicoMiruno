import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mygallery/platform/image_service_android.dart';
import 'package:mygallery/platform/image_service_windows.dart';
import 'file_entry.dart';

abstract class ImageService {
  Future<FileEntry?> pickDirectoryPath();
  Future<List<String>> getImages(String directoryPath);
  Future<Image> getImage(String imagePath);
  FutureBuilder<Image> getImageSync(String imagePath);
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
