import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../provider/directory_entries_provider.dart';
import '../provider/thumbnail_config_provider.dart';
import 'image_grid_screen.dart';

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
