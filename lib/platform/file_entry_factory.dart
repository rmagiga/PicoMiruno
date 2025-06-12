// file_entry_factory.dart
import 'dart:io';
import 'file_entry.dart';
import 'file_entry_windows.dart';
import 'file_entry_android.dart';

Future<FileEntry> createFileEntry(dynamic base) async {
  if (Platform.isAndroid) {
    // SAF の DocumentFile の処理
    return DocumentFileEntry(base); // base は DocumentFile
  } else {
    return IOFileEntry(base); // base は File or Directory
  }
}
