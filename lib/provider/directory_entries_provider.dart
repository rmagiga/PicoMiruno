import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/folders.dart';
import '../platform/file_entry.dart';
import '../utils/logger.dart';

class DirectoryEntriesNotifier extends StateNotifier<List<DirectoryEntry>> {
  DirectoryEntriesNotifier(this._factory, this._foldersRepository) : super(<DirectoryEntry>[]);
  final DirectoryEntryFactory _factory;
  final FoldersRepository _foldersRepository;

  Future<void> loadFolders() async {
    final List<String> savedFolders = await _foldersRepository.loadFolders();
    final List<DirectoryEntry> directoryEntries = <DirectoryEntry>[];
    for (final String path in savedFolders) {
      try {
        final DirectoryEntry directoryEntry = await _factory.create(path);
        directoryEntries.add(directoryEntry);
      } catch (e) {
        logger.w('Error loading directory entry for $path: $e');
      }
    }
    state = directoryEntries;
  }

  Future<void> addFolder(BuildContext context) async {
    final DirectoryEntry? directoryEntry = await _factory.pickDirectory();
    if (directoryEntry == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('フォルダが選択されませんでした')));
      return;
    }
    state = <DirectoryEntry>[...state, directoryEntry];
    await _foldersRepository.saveFolders(state.map((DirectoryEntry e) => e.path).toList());
  }

  Future<void> removeFolder(int index) async {
    final List<DirectoryEntry> newList = <DirectoryEntry>[...state]..removeAt(index);
    state = newList;
    await _foldersRepository.saveFolders(state.map((DirectoryEntry e) => e.path).toList());
  }
}

final StateNotifierProvider<DirectoryEntriesNotifier, List<DirectoryEntry>>
directoryEntriesProvider = StateNotifierProvider<DirectoryEntriesNotifier, List<DirectoryEntry>>(
  (StateNotifierProviderRef<DirectoryEntriesNotifier, List<DirectoryEntry>> ref) =>
      DirectoryEntriesNotifier(DirectoryEntryFactory(), SharedPreferencesFoldersRepository()),
);
