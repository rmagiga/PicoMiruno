import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'full_screen_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageGridScreen extends ConsumerStatefulWidget {
  final String folderPath;
  final Directory cacheDir;
  const ImageGridScreen({
    super.key,
    required this.folderPath,
    required this.cacheDir,
  });

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen> {
  //List<String> allImagePaths = [];
  List<FileEntry> allImageEntries = [];
  //final _imageService = ImageServiceFactory.create();
  ScrollController? _scrollController;
  final directoryEntryFactory = DirectoryEntryFactory();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadImagePaths();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    imageCache.clear(); // FlutterのimageCacheもクリア
    super.dispose();
  }

  Future<void> _loadImagePaths() async {
    final directoryEntry = directoryEntryFactory.create(widget.folderPath);
    final imageEntryList = await directoryEntry.listFiles();
    // ディレクトリエントリがnullの場合は、フォルダが存在しないかアクセスできない
    setState(() {
      allImageEntries = imageEntryList;
    });
  }

  Widget _getThumbnailText(int index) {
    return Container(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          allImageEntries[index].name,
          style: const TextStyle(color: Colors.white, fontSize: 12.0),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // flutter_cache_managerでサムネイル画像を取得
  Widget getImageSync(FileEntry entry) {
    final cacheDir = widget.cacheDir;
    return FutureBuilder<Uint8List>(
      future: () async {
        final thumbnailPath = entry.getThumbnailPath(cacheDir);
        final cacheManager = DefaultCacheManager();
        final fileInfo = await cacheManager.getFileFromCache(thumbnailPath);
        if (fileInfo != null && await fileInfo.file.exists()) {
          return await fileInfo.file.readAsBytes();
        } else {
          final thumbBytes = await entry.thumbnailReadAsBytes(cacheDir);
          final file = await cacheManager.putFile(
            thumbnailPath, // key
            thumbBytes,
            fileExtension: 'jpg',
          );
          return await file.readAsBytes();
        }
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error, color: Colors.red);
        } else {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
      },
    );
  }

  Widget _getThumbnail(int index) {
    return SizedBox(
      width: 80,
      height: 80,
      child: getImageSync(allImageEntries[index]),
    );
  }

  Widget _buildEmptyView() {
    return const Center(child: Text('画像が見つかりません'));
  }

  Widget _buildGridView() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true, // 常にスクロールバーを表示
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(right: 16), // スクロールバー分の余白
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 90, // サムネイルの最大幅を固定（80+余白）
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          childAspectRatio: 1,
        ),
        itemCount: allImageEntries.length,
        itemBuilder: (context, index) {
          return _buildGridTile(index);
        },
      ),
    );
  }

  Widget _buildGridTile(int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FullScreenImage(
                    fileEntries: allImageEntries,
                    initialIndex: index,
                  ),
            ),
          );
        },
        child: GridTile(
          footer: _getThumbnailText(index),
          child: _getThumbnail(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderPath)),
      body: allImageEntries.isEmpty ? _buildEmptyView() : _buildGridView(),
    );
  }
}
