import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/file_entry.dart';

class FileEntryListNotifier extends StateNotifier<List<FileEntry>> {
  FileEntryListNotifier() : super(<FileEntry>[]);

  void add(FileEntry entry) {
    state = <FileEntry>[...state, entry];
  }

  void addAll(Iterable<FileEntry> entries) {
    state = <FileEntry>[...state, ...entries];
  }

  void clear() {
    state = <FileEntry>[];
  }
}

final StateNotifierProvider<FileEntryListNotifier, List<FileEntry>> fileEntryListProvider =
    StateNotifierProvider<FileEntryListNotifier, List<FileEntry>>(
      (StateNotifierProviderRef<FileEntryListNotifier, List<FileEntry>> ref) =>
          FileEntryListNotifier(),
    );
