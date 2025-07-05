import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../infrastructure/folders.dart';
import '../platform/file_entry.dart';
import '../utils/app_logger.dart';
import 'image_grid_screen.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  // --- Fields ---
  final DirectoryEntryFactory _factory = DirectoryEntryFactory();
  final FoldersRepository _foldersRepository = SharedPreferencesFoldersRepository();
  List<DirectoryEntry> _directoryEntries = <DirectoryEntry>[];
  late Directory _cacheDir;

  // --- Lifecycle ---
  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // --- Folder Operations ---
  Future<void> _loadFolders() async {
    _cacheDir = await getTemporaryDirectory();
    final List<String> savedFolders = await _foldersRepository.loadFolders();
    final List<DirectoryEntry> entries = <DirectoryEntry>[];
    for (final String path in savedFolders) {
      try {
        final DirectoryEntry entry = await _factory.create(path);
        entries.add(entry);
      } catch (e) {
        logger.d('フォルダ $path の読み込み中にエラーが発生しました: $e');
      }
    }
    setState(() => _directoryEntries = entries);
  }

  Future<void> _addFolder() async {
    final DirectoryEntry? entry = await _factory.pickDirectory();
    if (!mounted) {
      return;
    }
    if (entry == null) {
      _showSnackBar('フォルダが選択されませんでした');
      return;
    }
    setState(() => _directoryEntries.add(entry));
    await _saveFolders();
  }

  Future<void> _removeFolder(int index) async {
    setState(() => _directoryEntries.removeAt(index));
    await _saveFolders();
  }

  Future<void> _saveFolders() async {
    await _foldersRepository.saveFolders(
      _directoryEntries.map((DirectoryEntry e) => e.path).toList(),
    );
  }

  void _openFolder(DirectoryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ImageGridScreen(directoryEntry: entry, cacheDir: _cacheDir),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォルダ一覧'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _directoryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          final DirectoryEntry entry = _directoryEntries[index];
          return ListTile(
            title: Text(entry.viewPath),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeFolder(index),
            ),
            onTap: () => _openFolder(entry),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        tooltip: 'フォルダを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
