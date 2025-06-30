import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/theme_mode_provider.dart';
import '../provider/thumbnail_config_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController countController;
  late TextEditingController bytesController;

  @override
  void initState() {
    super.initState();
    final ThumbnailConfig thumbnailConfig = ref.read(thumbnailConfigProvider);
    countController = TextEditingController(text: thumbnailConfig.stalePeriodDays.toString());
    bytesController = TextEditingController(text: thumbnailConfig.maxDiskThumbnailCount.toString());
  }

  @override
  void dispose() {
    countController.dispose();
    bytesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final ThumbnailConfig thumbnailConfig = ref.watch(thumbnailConfigProvider);
    // 値が変更された場合、コントローラのテキストも更新
    if (countController.text != thumbnailConfig.stalePeriodDays.toString()) {
      countController.text = thumbnailConfig.stalePeriodDays.toString();
    }
    if (bytesController.text != thumbnailConfig.maxDiskThumbnailCount.toString()) {
      bytesController.text = thumbnailConfig.maxDiskThumbnailCount.toString();
    }
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
            const Text('サムネイルキャッシュ日数', style: TextStyle(fontSize: 16)),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: '日'),
                    onChanged: (String value) {
                      final int? v = int.tryParse(value);
                      if (v != null && v > 0) {
                        ref.read(thumbnailConfigProvider.notifier).setStalePeriodDays(v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('サムネイルキャッシュ最大個数', style: TextStyle(fontSize: 16)),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: bytesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: '個'),
                    onChanged: (String value) {
                      final int? v = int.tryParse(value);
                      if (v != null && v > 0) {
                        ref.read(thumbnailConfigProvider.notifier).setMaxDiskThumbnailCount(v);
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
