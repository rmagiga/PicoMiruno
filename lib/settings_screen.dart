import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  int _cacheLimitMb = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('画面モード', style: TextStyle(fontSize: 16)),
            DropdownButton<ThemeMode>(
              value: _themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('ライトモード')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('ダークモード')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('システム')),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  setState(() {
                    _themeMode = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            const Text('キャッシュの制限（MB）', style: TextStyle(fontSize: 16)),
            SizedBox(
              width: 120,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '例: 100'),
                controller: TextEditingController(
                  text: _cacheLimitMb.toString(),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _cacheLimitMb = parsed;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
