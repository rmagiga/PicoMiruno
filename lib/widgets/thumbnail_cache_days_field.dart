import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/thumbnail_config_provider.dart';

class ThumbnailCacheDaysField extends ConsumerWidget {
  const ThumbnailCacheDaysField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThumbnailConfig config = ref.watch(thumbnailConfigProvider);
    final TextEditingController controller = TextEditingController(
      text: config.stalePeriodDays.toString(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('サムネイルキャッシュ日数', style: TextStyle(fontSize: 16)),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
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
      ],
    );
  }
}
