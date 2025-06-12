// file_entry_android.dart
import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:mygallery/platform/file_entry_image_provider.dart';

import 'file_entry.dart';

// 仮想的なDocumentFileラッパー
class DocumentFileEntry implements FileEntry {
  final DocumentFile documentFile;

  DocumentFileEntry(this.documentFile);

  @override
  String get name => documentFile.name;

  @override
  String get path => documentFile.uri.toString();

  @override
  bool get isDirectory => documentFile.isDirectory;

  @override
  Future<List<FileEntry>> listFiles() async {
    final children = await documentFile.listDocuments();
    return children.map((e) => DocumentFileEntry(e)).toList();
  }
}

extension DocumentFileEntryImage on DocumentFileEntry {
  /// DocumentFileEntryからImageウィジェットを作成
  Image toImage({BoxFit fit = BoxFit.cover}) {
    // FileEntryImageProviderはDocumentFileEntryのdocumentFile.uriを利用して画像を読み込むカスタムImageProvider
    return Image(image: FileEntryThumbnailImageProvider(this), fit: fit);
  }
}
