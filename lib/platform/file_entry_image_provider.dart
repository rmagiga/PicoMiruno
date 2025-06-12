import 'dart:ui';

import 'package:docman/docman.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'file_entry_android.dart';

class FileEntryThumbnailImageProvider
    extends ImageProvider<FileEntryThumbnailImageProvider> {
  final DocumentFileEntry fileEntry;

  const FileEntryThumbnailImageProvider(this.fileEntry);

  @override
  Future<FileEntryThumbnailImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<FileEntryThumbnailImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    FileEntryThumbnailImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(
    FileEntryThumbnailImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);

    // DocumentFileEntryからバイトデータを取得
    final documentFile = key.fileEntry.documentFile;
    if (documentFile.isDirectory) {
      throw StateError('DocumentFileEntryはディレクトリです');
    }
    final documentThumbnail = await DocumentThumbnail.fromUri(
      documentFile.uri,
      width: 192,
      height: 192,
      png: true,
      quality: 100,
    );
    if (documentThumbnail == null) {
      throw StateError('DocumentThumbnailがnullです');
    }
    final bytes = documentThumbnail.bytes;
    if (bytes.isEmpty) {
      throw StateError('画像データが空です');
    }

    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }
}

Future<Image?> getThumbnailImage(String contentUriOrFilePath) async {
  final documentThumbnail = await DocumentThumbnail.fromUri(
    contentUriOrFilePath,
    width: 192,
    height: 192,
    png: true,
    quality: 100,
  );
  if (documentThumbnail != null) {
    final bytes = documentThumbnail.bytes;
    // Uint8ListからImageを作成
    return Image.memory(bytes);
  }
  return null;
}
