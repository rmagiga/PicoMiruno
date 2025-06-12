// file_entry_windows.dart
import 'dart:io';
import 'file_entry.dart';

class IOFileEntry implements FileEntry {
  final FileSystemEntity entity;

  IOFileEntry(this.entity);

  @override
  String get name => entity.uri.pathSegments.last;

  @override
  String get path => entity.path;

  @override
  bool get isDirectory => entity is Directory;

  @override
  Future<List<FileEntry>> listFiles() async {
    if (entity is Directory) {
      final children = await (entity as Directory).list().toList();
      return children.map((e) => IOFileEntry(e)).toList();
    }
    return [];
  }
}
