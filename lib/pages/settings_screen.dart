import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/theme_mode_provider.dart';
import '../provider/thumbnail_config_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final ThumbnailConfig thumbnailConfig = ref.watch(thumbnailConfigProvider);
    final TextEditingController countController = TextEditingController(
      text: thumbnailConfig.maxCount.toString(),
    );
    final TextEditingController bytesController = TextEditingController(
      text: (thumbnailConfig.maxBytes ~/ (1024 * 1024)).toString(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('画面モード', style: TextStyle(fontSize: 16)),
            DropdownButton<ThemeMode>(
              value: themeMode,
              items: const <DropdownMenuItem<ThemeMode>>[
                DropdownMenuItem<ThemeMode>(value: ThemeMode.light, child: Text('ライトモード')),
                DropdownMenuItem<ThemeMode>(value: ThemeMode.dark, child: Text('ダークモード')),
                DropdownMenuItem<ThemeMode>(value: ThemeMode.system, child: Text('システム')),
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
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: '個'),
                    onChanged: (String value) {
                      final int? v = int.tryParse(value);
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
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: bytesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'MB'),
                    onChanged: (String value) {
                      final int? v = int.tryParse(value);
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
