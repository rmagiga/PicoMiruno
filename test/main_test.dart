import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_miruno/main.dart';
import 'package:pico_miruno/pages/folder_list_screen.dart';
import 'package:pico_miruno/pages/full_screen_image.dart';
import 'package:pico_miruno/pages/image_grid_screen.dart';
import 'package:pico_miruno/pages/settings_screen.dart';
import 'package:pico_miruno/platform/file_entry.dart';
import 'package:pico_miruno/provider/theme_mode_provider.dart';

void main() {
  testWidgets('初期画面にFolderListScreenが表示されること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    // FolderListScreenのタイトルや特徴的なWidgetで判定
    expect(find.byType(FolderListScreen), findsOneWidget);
  });

  testWidgets('未定義ルートで初期画面に戻る', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/unknown');
    await tester.pumpAndSettle();
    expect(find.byType(FolderListScreen), findsOneWidget);
  });

  // テーマ切り替えのテスト例（light/dark）
  testWidgets('themeModeProviderがThemeMode.darkのときダークテーマになる', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        themeModeProvider.overrideWith(
          (StateNotifierProviderRef<ThemeModeNotifier, ThemeMode> ref) =>
              _MockDarkThemeModeNotifier(),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('MaterialAppのtitleがPicoMirunoであること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'PicoMiruno');
  });

  testWidgets('設定画面(SettingsScreen)に遷移できること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('フォルダーリスト画面(Routes.folderList)に遷移できること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/folderList');
    await tester.pumpAndSettle();
    expect(find.byType(FolderListScreen), findsOneWidget);
  });

  testWidgets('imageGrid画面に遷移できること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    // テスト用のDirectoryEntryとDirectoryを作成
    final DirectoryEntry entry = TestDirectoryEntry();
    final Directory cacheDir = Directory('.');
    navigator.pushNamed(
      '/imageGrid',
      arguments: <String, Object>{'directoryEntry': entry, 'cacheDir': cacheDir},
    );
    await tester.pumpAndSettle();
    expect(find.byType(ImageGridScreen), findsOneWidget);
  });

  testWidgets('fullScreenImage画面に遷移できること', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/fullScreenImage', arguments: <String, int>{'initialIndex': 0});
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenImage), findsOneWidget);
  });
}

class _MockDarkThemeModeNotifier extends ThemeModeNotifier {
  _MockDarkThemeModeNotifier() : super() {
    state = ThemeMode.dark;
  }
  @override
  Future<void> loadFromStorage() async {}
  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

// テスト用のDirectoryEntry実装
class TestDirectoryEntry implements DirectoryEntry {
  @override
  String get name => 'test';
  @override
  String get path => '/test';
  @override
  String get viewPath => '/test';
  @override
  Future<List<FileEntry>> listFiles() async => <FileEntry>[];
  @override
  Stream<FileEntry> listFilesStream() async* {
    // 空ストリーム
    return;
  }
}
