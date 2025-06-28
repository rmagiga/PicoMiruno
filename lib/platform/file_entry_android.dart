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
    final DocumentFile? documentFile = await DocMan.pick.directory();
    if (documentFile != null) {
      return DocumentFileDirectoryEntry.fromDocumentFile(documentFile);
    }
    // フォルダが選択されなかった場合はnullを返す
    return null;
  }
}

class ImageDocumentFileEntry extends FileEntry with ThumbnailMixin {

  ImageDocumentFileEntry(this.documentFile)
    : path = documentFile.uri {
    if (documentFile.isFile) {
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

  DocumentFileDirectoryEntry(this.path) {
    DocumentFile.fromUri(path).then((DocumentFile? docFile) {
      if (docFile == null || docFile.isFile) {
        throw Exception('Document file does not exist: $path');
      }
      documentFile = docFile;
    });
  }

  DocumentFileDirectoryEntry.fromDocumentFile(this.documentFile)
    : path = documentFile.uri;
  @override
  final String path;
  late DocumentFile documentFile;

  @override
  String get name => path.split('/').last;

  @override
  Future<List<FileEntry>> listFiles() async {
    final List<DocumentFile> documentFiles = await documentFile.listDocuments(
      extensions: imageExtensions,
    );
    documentFiles.sort((DocumentFile a, DocumentFile b) => a.lastModified.compareTo(b.lastModified));
    return documentFiles.map((DocumentFile docFile) {
      return ImageDocumentFileEntry(docFile);
    }).toList();
  }
}
