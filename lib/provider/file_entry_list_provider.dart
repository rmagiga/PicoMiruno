import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/file_entry.dart';

class FileEntryListNotifier extends StateNotifier<List<FileEntry>> {
  FileEntryListNotifier() : super([]);

  void add(FileEntry entry) {
    state = [...state, entry];
  }

  void addAll(Iterable<FileEntry> entries) {
    state = [...state, ...entries];
  }

  void clear() {
    state = [];
  }
}

final fileEntryListProvider = StateNotifierProvider<FileEntryListNotifier, List<FileEntry>>(
  (ref) => FileEntryListNotifier(),
);
