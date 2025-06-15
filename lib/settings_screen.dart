import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_provider.dart';
import 'thumbnail_config_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final thumbnailConfig = ref.watch(thumbnailConfigProvider);
    final countController = TextEditingController(
      text: thumbnailConfig.maxCount.toString(),
    );
    final bytesController = TextEditingController(
      text: (thumbnailConfig.maxBytes ~/ (1024 * 1024)).toString(),
    );
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
            const SizedBox(height: 32),
            const Text('サムネイルキャッシュ最大数', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: '個'),
                    onChanged: (value) {
                      final v = int.tryParse(value);
                      if (v != null && v > 0) {
                        ref
                            .read(thumbnailConfigProvider.notifier)
                            .setMaxCount(v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('サムネイルキャッシュ最大容量 (MB)', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bytesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'MB'),
                    onChanged: (value) {
                      final v = int.tryParse(value);
                      if (v != null && v > 0) {
                        ref
                            .read(thumbnailConfigProvider.notifier)
                            .setMaxBytes(v * 1024 * 1024);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
