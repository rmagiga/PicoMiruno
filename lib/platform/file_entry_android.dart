// file_entry_android.dart
import 'dart:typed_data';

import 'package:docman/docman.dart';

import '../utils/app_logger.dart';
import 'file_entry.dart';

class DocumentFileDirectoryEntryFactory implements DirectoryEntryFactory {
  @override
  Future<DirectoryEntry> create(String path) async {
    final DocumentFile? documentFile = await DocumentFile.fromUri(path);
    if (documentFile == null || documentFile.isFile || !documentFile.exists) {
      logger.d('ドキュメントファイルが存在しないかディレクトリではありません: $path');
      throw Exception('ドキュメントファイルが存在しないかディレクトリではありません: $path');
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
      logger.d('ファイルではないか、存在しません: $path');
      throw Exception('ファイルではないか、存在しません: $path');
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
      logger.d('ファイルの読み込みに失敗しました: $path');
      throw Exception('ファイルの読み込みに失敗しました: $path');
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
      logger.e('ディレクトリ内のファイル一覧取得に失敗しました: $path, エラー: $e');
      throw Exception('ディレクトリ内のファイル一覧取得に失敗しました: $path, エラー: $e');
    }
    if (documentFiles.isEmpty) {
      return <FileEntry>[];
    }
    documentFiles.sort(
      (DocumentFile a, DocumentFile b) => a.lastModified.compareTo(b.lastModified),
    );

    final List<FileEntry> fileEntries =
        documentFiles.map((DocumentFile docFile) {
          return ImageDocumentFileEntry(docFile);
        }).toList();
    return fileEntries;
  }

  @override
  Stream<FileEntry> listFilesStream() {
    return documentFile
        .listDocumentsStream(extensions: imageExtensions)
        .map((DocumentFile docFile) => ImageDocumentFileEntry(documentFile));
  }
}
