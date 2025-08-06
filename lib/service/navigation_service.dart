import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';

/// ナビゲーション処理を担当するサービスのインターフェース
abstract class INavigationService {
  void navigateToFullScreenImage(BuildContext context, List<FileEntry> files, int initialIndex);
}

/// ナビゲーション処理の具象実装
class NavigationService implements INavigationService {
  @override
  void navigateToFullScreenImage(BuildContext context, List<FileEntry> files, int initialIndex) {
    Navigator.pushNamed(
      context,
      Routes.fullScreenImage,
      arguments: <String, Object>{'fileEntries': files, 'initialIndex': initialIndex},
    );
  }
}
