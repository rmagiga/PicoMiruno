import 'package:flutter/material.dart';

import '../platform/file_entry.dart';
import '../utils/thumbnail_service.dart';
import 'thumbnail_image_widget.dart';

/// 画像グリッドを表示するウィジェット
class ImageGridWidget extends StatelessWidget {
  const ImageGridWidget({
    super.key,
    required this.files,
    required this.thumbnailService,
    required this.onImageTap,
    this.itemWidth = 120.0,
  });

  final List<FileEntry> files;
  final IThumbnailService thumbnailService;
  final void Function(int index) onImageTap;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = (constraints.maxWidth / itemWidth).floor().clamp(1, 10);
        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: files.length,
          itemBuilder: (BuildContext context, int index) {
            final FileEntry entry = files[index];
            return ThumbnailImageWidget(
              fileEntry: entry,
              thumbnailService: thumbnailService,
              onTap: () => onImageTap(index),
            );
          },
        );
      },
    );
  }
}
