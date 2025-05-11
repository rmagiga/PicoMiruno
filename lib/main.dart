import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'image_grid_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const FolderListScreen(),
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

  Future<void> _addFolder() async {
    String? selectedDirectory;

    if (Platform.isWindows) {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    } else {
      // SAFを使用してフォルダ選択を実装（Android用）
      selectedDirectory = '/path/to/folder'; // 仮のフォルダパス
    }

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _folders.add(selectedDirectory!);
        prefs.setStringList('folders', _folders);
      });
    }
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
      appBar: AppBar(title: const Text('フォルダ一覧')),
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
