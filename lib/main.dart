import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mygallery/platform/image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_grid_screen.dart';
import 'settings_screen.dart';
import 'theme_mode_provider.dart';
import 'thumbnail_config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // すべての設定をロード
  final container = ProviderContainer();
  await Future.wait([
    container.read(themeModeProvider.notifier).loadFromStorage(),
    container.read(thumbnailConfigProvider.notifier).loadFromStorage(),
  ]);
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const FolderListScreen(),
      routes: {'/settings': (context) => const SettingsScreen()},
    );
  }
}

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _folders = prefs.getStringList('folders') ?? [];
    });
  }

  Future<DocumentFile?> pickDirectoryPath() => DocMan.pick.directory();

  Future<void> _addFolder() async {
    var imageService = ImageServiceFactory.create();

    var fileEntry = await imageService.pickDirectoryPath();
    if (fileEntry == null || fileEntry.isDirectory == false) {
      if (!mounted) return;
      // ユーザーがフォルダを選択しなかった場合の処理
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('フォルダが選択されませんでした')));
      }
      return;
    }

    String selectedDirectory = fileEntry.path;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _folders.add(selectedDirectory);
      prefs.setStringList('folders', _folders);
    });
  }

  void _openFolder(String folderPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGridScreen(folderPath: folderPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォルダ一覧'),
        actions: [
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
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_folders[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
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

Future<void> addFolderToPrefs(
  BuildContext context, {
  void Function(String folderPath)? onAdded,
}) async {
  var imageService = ImageServiceFactory.create();
  var fileEntry = await imageService.pickDirectoryPath();
  if (fileEntry == null || fileEntry.isDirectory == false) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フォルダが選択されませんでした')));
    }
    return;
  }
  String selectedDirectory = fileEntry.path;
  final prefs = await SharedPreferences.getInstance();
  final folders = prefs.getStringList('folders') ?? [];
  folders.add(selectedDirectory);
  await prefs.setStringList('folders', folders);
  if (onAdded != null) onAdded(selectedDirectory);
}
