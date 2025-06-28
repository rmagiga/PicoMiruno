import 'dart:io';

import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'image_grid_screen.dart';
import 'platform/file_entry.dart';
import 'settings_screen.dart';
import 'theme_mode_provider.dart';
import 'thumbnail_config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // すべての設定をロード
  final ProviderContainer container = ProviderContainer();
  await Future.wait(<Future<void>>[
    container.read(themeModeProvider.notifier).loadFromStorage(),
    container.read(thumbnailConfigProvider.notifier).loadFromStorage(),
  ]);
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const FolderListScreen(),
      routes: <String, WidgetBuilder>{'/settings': (BuildContext context) => const SettingsScreen()},
    );
  }
}

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<String> _folders = <String>[];
  late Directory _cacheDir;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    _cacheDir = await getTemporaryDirectory();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _folders = prefs.getStringList('folders') ?? <String>[];
    });
  }

  Future<DocumentFile?> pickDirectoryPath() => DocMan.pick.directory();

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

    final String selectedDirectory = directoryEntry.path;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _folders.add(selectedDirectory);
      prefs.setStringList('folders', _folders);
    });
  }

  void _openFolder(String folderPath) {
    Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (BuildContext context) =>
                ImageGridScreen(folderPath: folderPath, cacheDir: _cacheDir),
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
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(_folders[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                setState(() {
                  _folders.removeAt(index);
                  prefs.setStringList('folders', _folders);
                });
              },
            ),
            onTap: () => _openFolder(_folders[index]),
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
