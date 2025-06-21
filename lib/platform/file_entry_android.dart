// file_entry_android.dart
import 'package:docman/docman.dart';

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
}
