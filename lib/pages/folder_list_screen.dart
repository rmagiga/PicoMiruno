import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../infrastructure/folders.dart';
import '../platform/file_entry.dart';
import '../provider/thumbnail_config_provider.dart';
import '../utils/logger.dart';
import 'image_grid_screen.dart';

// Riverpod StateNotifier
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

class FolderListScreen extends ConsumerStatefulWidget {
  const FolderListScreen({super.key});

  @override
  ConsumerState<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends ConsumerState<FolderListScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(directoryEntriesProvider.notifier).loadFolders();
  }

  void _openFolder(DirectoryEntry directoryEntry) {
    final ThumbnailConfig thumbnailConfig = ref.read(thumbnailConfigProvider);
    Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (BuildContext context) => ImageGridScreen(
              directoryEntry: directoryEntry,
              cacheDir: thumbnailConfig.thumbnailDirectory,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DirectoryEntry> directoryEntries = ref.watch(directoryEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォルダ一覧'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: directoryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(directoryEntries[index].viewPath),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await ref.read(directoryEntriesProvider.notifier).removeFolder(index);
              },
            ),
            onTap: () => _openFolder(directoryEntries[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(directoryEntriesProvider.notifier).addFolder(context);
        },
        tooltip: 'フォルダを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
