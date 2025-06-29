import 'package:shared_preferences/shared_preferences.dart';

abstract class FoldersRepository {
  Future<List<String>> loadFolders();

  Future<void> saveFolders(List<String> folders);
}

class SharedPreferencesFoldersRepository implements FoldersRepository {
  static const String _key = 'folders';

  @override
  Future<List<String>> loadFolders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  @override
  Future<void> saveFolders(List<String> folders) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, folders);
  }
}
