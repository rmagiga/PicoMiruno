// file_entry_android.dart
import 'dart:developer';
import 'dart:typed_data';

import 'package:docman/docman.dart';

import 'file_entry.dart';

class DocumentFileDirectoryEntryFactory implements DirectoryEntryFactory {
  @override
  Future<DirectoryEntry> create(String path) async {
    final DocumentFile? documentFile = await DocumentFile.fromUri(path);
    if (documentFile == null || documentFile.isFile || !documentFile.exists) {
      log('Document file does not exist or is not a directory: $path');
      throw Exception('Document file does not exist: $path');
    }
    return DocumentFileDirectoryEntry(documentFile);
  }

  @override
  Future<DirectoryEntry?> pickDirectory() async {
    // Android用のフォルダ選択ロジックを実装
    final DocumentFile? documentFile = await DocMan.pick.directory();
    if (documentFile != null) {
      return DocumentFileDirectoryEntry(documentFile);
    }
    // フォルダが選択されなかった場合はnullを返す
    return null;
  }
}

class ImageDocumentFileEntry extends FileEntry with ThumbnailMixin {
  ImageDocumentFileEntry(this.documentFile) : path = documentFile.uri {
    if (!documentFile.isFile || !documentFile.exists) {
      log('Not a file or does not exist: $path');
      throw Exception('Not a file: $path');
    }
  }

  @override
  final String path;
  final DocumentFile documentFile;

  @override
  String get name => documentFile.name;

  @override
  Future<Uint8List> readAsBytes() async {
    final Uint8List? bytes = await documentFile.read();
    if (bytes == null || bytes.isEmpty) {
      log('Failed to read file: $path');
      throw Exception('Failed to read file: $path');
    }
    return bytes;
  }

  @override
  int getLastModifiedTime() {
    return documentFile.lastModified;
  }
}

class DocumentFileDirectoryEntry extends DirectoryEntry {
  DocumentFileDirectoryEntry(this.documentFile) : path = documentFile.uri;

  @override
  final String path;
  late DocumentFile documentFile;

  @override
  String get name => Uri.decodeFull(path.split('/').last);

  @override
  String get viewPath => Uri.decodeFull(path);

  @override
  Future<List<FileEntry>> listFiles() async {
    late final List<DocumentFile> documentFiles;
    try {
      documentFiles = await documentFile.listDocuments();
    } catch (e) {
      log('Failed to list files in directory: $path, error: $e');
      throw Exception('Failed to list files in directory: $path, error: $e');
    }
    if (documentFiles.isEmpty) {
      return <FileEntry>[];
    }
    documentFiles.sort(
      (DocumentFile a, DocumentFile b) => a.lastModified.compareTo(b.lastModified),
    );

    for (final DocumentFile c in documentFiles) {
      log('Document file: ${c.name}, last modified: ${c.lastModified}');
    }
    final List<FileEntry> fileEntries =
        documentFiles.map((DocumentFile docFile) {
          return ImageDocumentFileEntry(docFile);
        }).toList();
    return fileEntries;
  }
}
