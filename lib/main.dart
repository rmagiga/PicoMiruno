import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_constants.dart';
import 'pages/folder_list_screen.dart';
import 'pages/full_screen_image.dart';
import 'pages/image_grid_screen.dart';
import 'pages/settings_screen.dart';

import 'platform/file_entry.dart';
import 'provider/theme_mode_provider.dart';
import 'provider/thumbnail_config_provider.dart';
import 'utils/app_logger.dart';

// ignore: unreachable_from_main

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // すべての設定をロード
  final ProviderContainer container = ProviderContainer();
  await Future.wait(<Future<void>>[
    container.read(themeModeProvider.notifier).loadFromStorage(),
    container.read(thumbnailConfigProvider.notifier).loadFromStorage(),
  ]);
  setupLogger();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

T getArgument<T>(Object? arguments, String key) {
  if (arguments is Map<String, dynamic>) {
    final dynamic value = arguments[key];
    if (value is T) {
      return value;
    }
  }
  logger.d('Argument for key "$key" is not of type $T or not found.');
  throw ArgumentError('Invalid argument type or key not found: $key');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PicoMiruno',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const FolderListScreen(),
      onGenerateRoute: route,
    );
  }

  Route<dynamic>? route(RouteSettings settings) {
    switch (settings.name) {
      case Routes.settings:
        return MaterialPageRoute<void>(builder: (BuildContext context) => const SettingsScreen());
      case Routes.folderList:
        return MaterialPageRoute<void>(builder: (BuildContext context) => const FolderListScreen());
      case Routes.imageGrid:
        final DirectoryEntry directoryEntry = getArgument<DirectoryEntry>(
          settings.arguments,
          RouteArguments.directoryEntry,
        );
        final Directory cacheDir = getArgument<Directory>(
          settings.arguments,
          RouteArguments.cacheDir,
        );
        return MaterialPageRoute<void>(
          builder:
              (BuildContext context) =>
                  ImageGridScreen(directoryEntry: directoryEntry, cacheDir: cacheDir),
        );
      case Routes.fullScreenImage:
        final int initialIndex = getArgument<int>(settings.arguments, RouteArguments.initialIndex);
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => FullScreenImage(initialIndex: initialIndex),
        );
    }
    return MaterialPageRoute<void>(builder: (BuildContext context) => const FolderListScreen());
  }
}
