import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../utils/thumbnail_service.dart';

/// サムネイル画像を表示するウィジェット
class ThumbnailImageWidget extends StatelessWidget {
  const ThumbnailImageWidget({
    super.key,
    required this.fileEntry,
    required this.thumbnailService,
    required this.onTap,
  });

  final FileEntry fileEntry;
  final IThumbnailService thumbnailService;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<Uint8List>(
        future: thumbnailService.getThumbnail(fileEntry),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return const Icon(Icons.broken_image, color: Colors.red);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snap.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: ThumbnailConstants.thumbSize,
              cacheHeight: ThumbnailConstants.thumbSize,
            ),
          );
        },
      ),
    );
  }
}
