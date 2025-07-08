// file_entry_windows.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'file_entry.dart';

class IOFileDirectoryEntryFactory implements DirectoryEntryFactory {
  @override
  Future<DirectoryEntry> create(String path) async {
    return IOFileDirectoryEntry(path);
  }

  @override
  Future<DirectoryEntry?> pickDirectory() async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return null;
    }
    return IOFileDirectoryEntry(directoryPath);
  }
}

class ImageFileEntry extends FileEntry with ThumbnailMixin {
  ImageFileEntry(this.path) : file = File(path) {
    if (!file.existsSync()) {
      log('File does not exist: $path');
      throw Exception('File does not exist: $path');
    }
  }

  ImageFileEntry.fromFile(this.file) : path = file.path {
    if (!file.existsSync()) {
      log('File does not exist: ${file.path}');
      throw Exception('File does not exist: ${file.path}');
    }
  }

  @override
  final String path;
  final File file;

  @override
  String get name => path.split(Platform.pathSeparator).last;

  @override
  Future<Uint8List> readAsBytes() async {
    return file.readAsBytes();
  }

  @override
  int getLastModifiedTime() {
    return file.lastModifiedSync().millisecondsSinceEpoch;
  }
}

class IOFileDirectoryEntry extends DirectoryEntry {
  IOFileDirectoryEntry(this.path) : directory = Directory(path) {
    if (!directory.existsSync()) {
      log('Directory does not exist: $path');
      throw Exception('Directory does not exist: $path');
    }
  }

  @override
  final String path;
  final Directory directory;

  @override
  String get viewPath => path;

  @override
  String get name => path.split(Platform.pathSeparator).last;

  @override
  Future<List<FileEntry>> listFiles() async {
    final bool exists = directory.existsSync();
    if (!exists) {
      return <FileEntry>[];
    }
    final List<ImageFileEntry> files =
        directory
            .listSync(followLinks: false)
            .whereType<File>()
            .where((File file) => _isImageFile(file))
            .map((File file) => ImageFileEntry.fromFile(file))
            .toList();

    files.sort((ImageFileEntry a, ImageFileEntry b) {
      return a.getLastModifiedTime().compareTo(b.getLastModifiedTime());
    });

    return files;
  }

  bool _isImageFile(File file) {
    final String extension = p.extension(file.path).toLowerCase();
    return imageExtensions.contains(extension);
  }

  @override
  Future<Stream<FileEntry>> listFilesAsStream() async {
    final StreamController<FileEntry> controller = StreamController<FileEntry>();
    try {
      directory
          .list(followLinks: false)
          .listen(
            (FileSystemEntity entity) {
              if (entity is File && _isImageFile(entity)) {
                controller.add(ImageFileEntry.fromFile(entity));
              }
            },
            onDone: controller.close,
            onError: (Object error) {
              log('Error listing files in directory: $path, error: $error');
              controller.addError(error);
            },
          );
    } catch (e) {
      log('Failed to list files in directory: $path, error: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}
