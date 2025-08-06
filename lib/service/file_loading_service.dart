import '../platform/file_entry.dart';

/// ファイル読み込み処理を担当するサービスのインターフェース
abstract class IFileLoadingService {
  Future<List<FileEntry>> loadFiles(DirectoryEntry directoryEntry);
}

/// ファイル読み込み処理の具象実装
class FileLoadingService implements IFileLoadingService {
  @override
  Future<List<FileEntry>> loadFiles(DirectoryEntry directoryEntry) async {
    return directoryEntry.listFiles();
  }
}
