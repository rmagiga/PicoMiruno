// file_entry_windows.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'file_entry.dart';
import 'package:path/path.dart' as p;

class IOFileDirectoryEntryFactory implements DirectoryEntryFactory {
  @override
  DirectoryEntry create(String path) {
    return IOFileDirectoryEntry(path);
  }

  @override
  Future<DirectoryEntry?> pickDirectory() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return null;
    }
    return IOFileDirectoryEntry(directoryPath);
  }
}

class ImageFileEntry extends FileEntry with ThumbnailMixin {
  @override
  final String path;
  final File file;

  ImageFileEntry(this.path) : file = File(path) {
    if (!file.existsSync()) {
      throw Exception('File does not exist: $path');
    }
  }

  ImageFileEntry.fromFile(this.file) : path = file.path {
    if (!file.existsSync()) {
      throw Exception('File does not exist: ${file.path}');
    }
  }

  @override
  String get name => path.split(Platform.pathSeparator).last;

  @override
  Future<Uint8List> readAsBytes() async {
    return await file.readAsBytes();
  }
}

class IOFileDirectoryEntry extends DirectoryEntry {
  @override
  final String path;
  final Directory directory;
  IOFileDirectoryEntry(this.path) : directory = Directory(path) {
    if (!directory.existsSync()) {
      throw Exception('Directory does not exist: $path');
    }
  }

  @override
  String get name => path.split(Platform.pathSeparator).last;

  @override
  Future<List<FileEntry>> listFiles() async {
    bool exists = await directory.exists();
    if (!exists) {
      return [];
    }
    return directory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) {
          return hasImageFile(file);
        })
        .map((file) {
          return ImageFileEntry.fromFile(file);
        })
        .toList();
  }

  bool hasImageFile(File file) {
    String extension = p.extension(file.path).toLowerCase();
    return imageExtensions.contains(extension);
  }
}
