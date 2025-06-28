import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import 'image_grid_screen.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}
class _FolderListScreenState extends State<FolderListScreen> {
  List<DirectoryEntry> _directoryEntries = <DirectoryEntry>[];
  late Directory _cacheDir;
  final DirectoryEntryFactory _factory = DirectoryEntryFactory();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    _cacheDir = await getTemporaryDirectory();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedFolders = prefs.getStringList('folders') ?? <String>[];

    final List<DirectoryEntry> directoryEntries = <DirectoryEntry>[];
    for (final String path in savedFolders) {
      try {
        final DirectoryEntry directoryEntry = await _factory.create(path);
        directoryEntries.add(directoryEntry);
      } catch (e) {
        // エラーが発生した場合はログに出力し、フォルダをスキップ
        log('Error loading directory entry for $path: $e');
      }
    }
    setState(() {
      _directoryEntries = directoryEntries;
    });
  }

  Future<void> _addFolder() async {
    final DirectoryEntry? directoryEntry = await DirectoryEntryFactory().pickDirectory();

    if (directoryEntry == null) {
      if (!mounted) {
        return;
      }
      // ユーザーがフォルダを選択しなかった場合の処理
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('フォルダが選択されませんでした')));
      }
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _directoryEntries.add(directoryEntry);
      prefs.setStringList('folders', _directoryEntries.map((DirectoryEntry entry) => entry.path).toList());
    });
  }

  void _openFolder(DirectoryEntry directoryEntry) {
    Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (BuildContext context) =>
            ImageGridScreen(directoryEntry: directoryEntry, cacheDir: _cacheDir),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォルダ一覧'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 設定画面への遷移（後で画面を作成）
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _directoryEntries.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(_directoryEntries[index].viewPath),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                setState(() {
                  _directoryEntries.removeAt(index);
                  prefs.setStringList('folders', _directoryEntries.map((DirectoryEntry entry) => entry.path).toList());
                });
              },
            ),
            onTap: () => _openFolder(_directoryEntries[index]),
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
