import 'dart:typed_data';
import '../platform/file_entry.dart';

/// 画像取得サービスの抽象クラス（DIP）
abstract class ImageProviderService {
  Future<Uint8List> getImageBytes(FileEntry fileEntry);
}
