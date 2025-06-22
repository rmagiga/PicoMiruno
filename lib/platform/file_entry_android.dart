// file_entry_android.dart
import 'dart:typed_data';

import 'package:docman/docman.dart';
import 'file_entry.dart';

class DocumentFileDirectoryEntryFactory implements DirectoryEntryFactory {
  @override
  DirectoryEntry create(String path) {
    return DocumentFileDirectoryEntry(path);
  }

  @override
  Future<DirectoryEntry?> pickDirectory() async {
    // Android用のフォルダ選択ロジックを実装
    var documentFile = await DocMan.pick.directory();
    if (documentFile != null) {
      return DocumentFileDirectoryEntry.fromDocumentFile(documentFile);
    }
    // フォルダが選択されなかった場合はnullを返す
    return null;
  }
}

class ImageDocumentFileEntry extends FileEntry with ThumbnailMixin {
  @override
  final String path;
  final DocumentFile documentFile;

  ImageDocumentFileEntry(this.documentFile)
    : path = documentFile.uri.toString() {
    if (documentFile.isFile) {
      throw Exception('Not a file: $path');
    }
  }

  @override
  String get name => documentFile.name;

  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = await documentFile.read();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to read file: $path');
    }
    return bytes;
  }
}

class DocumentFileDirectoryEntry extends DirectoryEntry {
  @override
  final String path;
  late DocumentFile documentFile;

  DocumentFileDirectoryEntry(this.path) {
    DocumentFile.fromUri(path).then((docFile) {
      if (docFile == null || docFile.isFile) {
        throw Exception('Document file does not exist: $path');
      }
      documentFile = docFile;
    });
  }

  DocumentFileDirectoryEntry.fromDocumentFile(this.documentFile)
    : path = documentFile.uri.toString();

  @override
  String get name => path.split('/').last;

  @override
  Future<List<FileEntry>> listFiles() async {
    final documentFiles = await documentFile.listDocuments(
      extensions: imageExtensions,
    );
    return documentFiles.map((docFile) {
      return ImageDocumentFileEntry(docFile);
    }).toList();
  }
}
