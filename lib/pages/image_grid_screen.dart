import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../provider/file_entry_list_provider.dart';
import '../provider/thumbnail_config_provider.dart';
import '../utils/thumbnail_service.dart';

class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({super.key, required this.directoryEntry, required this.cacheDir});

  final DirectoryEntry directoryEntry;
  final Directory cacheDir;

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen> {
  final double _itemWidth = 120;
  final DirectoryEntryFactory factory = DirectoryEntryFactory();
  Stream<FileEntry>? _filesStream;
  StreamSubscription<FileEntry>? _subscription;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _filesStream = widget.directoryEntry.listFilesStream();
    ref.read(thumbnailConfigProvider.notifier).loadFromStorage();
    // Providerのリストを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileEntryListProvider.notifier).clear();
      _startListening();
    });
  }

  void _startListening() {
    _subscription = _filesStream?.listen(
      (FileEntry entry) {
        ref.read(fileEntryListProvider.notifier).add(entry);
        if (_loading) {
          setState(() {
            _loading = false;
          });
        }
      },
      onError: (_) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      },
      onDone: () {
        setState(() {
          _loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThumbnailConfig thumbnailConfig = ref.watch(thumbnailConfigProvider);
    final List<FileEntry> files = ref.watch(fileEntryListProvider);
    // 更新日時の降順でソート
    final List<FileEntry> sortedFiles = List<FileEntry>.from(files)..sort(
      (FileEntry a, FileEntry b) => b.getLastModifiedTime().compareTo(a.getLastModifiedTime()),
    );
    final IThumbnailService thumbnailService = ThumbnailService(
      cacheDir: widget.cacheDir,
      thumbSize: ThumbnailConstants.thumbSize,
      stalePeriodDays: thumbnailConfig.stalePeriodDays,
      maxNrOfCacheObjects: thumbnailConfig.maxDiskThumbnailCount,
    );

    if (_loading && sortedFiles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError) {
      return const Scaffold(body: Center(child: Text('画像の取得に失敗しました')));
    }
    if (sortedFiles.isEmpty) {
      return const Scaffold(body: Center(child: Text('画像がありません')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.directoryEntry.name)),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int crossAxisCount = (constraints.maxWidth / _itemWidth).floor().clamp(1, 10);
          return GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: sortedFiles.length,
            itemBuilder: (BuildContext context, int index) {
              final FileEntry entry = sortedFiles[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.fullScreenImage,
                    arguments: <String, Object>{'initialIndex': index},
                  );
                },
                child: FutureBuilder<Uint8List>(
                  future: thumbnailService.getThumbnail(entry),
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
            },
          );
        },
      ),
    );
  }
}
