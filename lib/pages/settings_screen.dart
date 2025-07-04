import 'package:flutter/material.dart';

import '../widgets/theme_mode_selector.dart';
import '../widgets/thumbnail_cache_count_field.dart';
import '../widgets/thumbnail_cache_days_field.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ThemeModeSelector(),
            SizedBox(height: 32),
            ThumbnailCacheDaysField(),
            SizedBox(height: 16),
            ThumbnailCacheCountField(),
          ],
        ),
      ),
    );
  }
}
