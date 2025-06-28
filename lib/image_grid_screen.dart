import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'full_screen_image.dart';
import 'platform/file_entry.dart';
import 'utils/thumbnail_provider.dart';

class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({
    super.key,
    required this.folderPath,
    required this.cacheDir,
  });
  final String folderPath;
  final Directory cacheDir;

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen> {
  late Future<List<FileEntry>> _filesFuture;
  late final ThumbnailProvider _thumbnailProvider;
  final double _itemWidth = 120;

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
    _thumbnailProvider = ThumbnailProvider(cacheDir: widget.cacheDir);
  }

  Future<List<FileEntry>> _loadFiles() async {
    final DirectoryEntryFactory factory = DirectoryEntryFactory();
    final DirectoryEntry dirEntry = factory.create(widget.folderPath);
    final List<FileEntry> files = await dirEntry.listFiles();
    files.sort(
      (FileEntry a, FileEntry b) => b.getLastModifiedTime().compareTo(a.getLastModifiedTime()),
    );
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderPath)),
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
              final int crossAxisCount = (constraints.maxWidth / _itemWidth)
                  .floor()
                  .clamp(1, 10);
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
                      Navigator.of(context).push(
                        MaterialPageRoute<dynamic>(
                          builder:
                              (BuildContext context) => FullScreenImage(
                                fileEntries: files,
                                initialIndex: index,
                              ),
                        ),
                      );
                    },
                    child: FutureBuilder<Uint8List>(
                      future: _thumbnailProvider.getThumbnail(entry),
                      builder: (BuildContext context, AsyncSnapshot<Uint8List> snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        if (snap.hasError || !snap.hasData) {
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.red,
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snap.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: _thumbnailProvider.thumbSize,
                            cacheHeight: _thumbnailProvider.thumbSize,
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
