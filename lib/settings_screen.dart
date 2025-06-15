import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('画面モード', style: TextStyle(fontSize: 16)),
            DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('ライトモード')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('ダークモード')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('システム')),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
