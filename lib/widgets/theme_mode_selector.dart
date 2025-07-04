import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/theme_mode_provider.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return Column(
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
      ],
    );
  }
}
