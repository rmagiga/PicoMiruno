import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../provider/current_image_index_provider.dart';
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
  late Future<List<FileEntry>> _filesFuture;
  final double _itemWidth = 120;
  final DirectoryEntryFactory factory = DirectoryEntryFactory();

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
  }

  Future<List<FileEntry>> _loadFiles() async {
    final List<FileEntry> files = await widget.directoryEntry.listFiles();
    return files;
  }

  @override
  Widget build(BuildContext context) {
    final ThumbnailConfig thumbnailConfig = ref.watch(thumbnailConfigProvider);
    late final IThumbnailService thumbnailService = ThumbnailService(
      cacheDir: widget.cacheDir,
      thumbSize: ThumbnailConstants.thumbSize,
      stalePeriodDays: thumbnailConfig.stalePeriodDays,
      maxNrOfCacheObjects: thumbnailConfig.maxDiskThumbnailCount,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.directoryEntry.name)),
      body: FutureBuilder<List<FileEntry>>(
        future: _filesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<FileEntry>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('画像がありません'));
          }
          final List<FileEntry> files = snapshot.data!;
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int crossAxisCount = (constraints.maxWidth / _itemWidth).floor().clamp(1, 10);
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
                  return GestureDetector(
                    onTap: () {
                      ref.read(currentImageIndexProvider.notifier).index = index;

                      Navigator.pushNamed(
                        context,
                        Routes.fullScreenImage,
                        arguments: <String, Object>{'fileEntries': files, 'initialIndex': index},
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
          );
        },
      ),
    );
  }
}
