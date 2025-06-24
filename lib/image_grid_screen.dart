import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'full_screen_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LimitedCacheManager extends CacheManager {
  static const key = 'limitedThumbCache';
  static final LimitedCacheManager _instance = LimitedCacheManager._();
  factory LimitedCacheManager() => _instance;
  LimitedCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 300, // サムネイル最大100個まで
          // maxSize: 50 * 1024 * 1024, // 最大50MB → 削除
        ),
      );
}

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
  static const int pageSize = 40; // 1ページあたりの画像数
  List<FileEntry> allImageEntries = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  List<FileEntry> _allEntriesBuffer = [];
  ScrollController? _scrollController;
  final directoryEntryFactory = DirectoryEntryFactory();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController?.addListener(_onScroll);
    _initLoad();
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    imageCache.clear(); // FlutterのimageCacheもクリア
    super.dispose();
  }

  Future<void> _initLoad() async {
    setState(() {
      _isLoading = true;
      allImageEntries.clear();
      _allEntriesBuffer = [];
      _currentPage = 0;
      _hasMore = true;
    });
    final directoryEntry = directoryEntryFactory.create(widget.folderPath);
    final imageEntryList = await directoryEntry.listFiles();
    setState(() {
      _allEntriesBuffer = imageEntryList;
      _hasMore = _allEntriesBuffer.isNotEmpty;
      _isLoading = false;
    });
    await _loadNextPage();
  }

  void _onScroll() {
    if (_scrollController == null || !_hasMore || _isLoading) return;
    if (_scrollController!.position.pixels >=
        _scrollController!.position.maxScrollExtent - 500) {
      // 先読みを早めに
      _loadNextPage();
    }
  }

  Future<void> _prefetchThumbnails(List<FileEntry> entries) async {
    for (final entry in entries) {
      final cacheDir = widget.cacheDir;
      final thumbnailPath = entry.getThumbnailPath(cacheDir);
      final cacheManager = LimitedCacheManager();
      final fileInfo = await cacheManager.getFileFromCache(thumbnailPath);
      Uint8List? bytes;
      if (fileInfo != null && await fileInfo.file.exists()) {
        bytes = await fileInfo.file.readAsBytes();
      } else {
        try {
          bytes = await entry.thumbnailReadAsBytes(cacheDir);
          await cacheManager.putFile(
            thumbnailPath,
            bytes,
            fileExtension: 'jpg',
          );
        } catch (_) {
          continue;
        }
      }
      if (mounted) {
        await precacheImage(MemoryImage(bytes), context);
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (!_hasMore || _isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final start = _currentPage * pageSize;
    final end = start + pageSize;
    if (start >= _allEntriesBuffer.length) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }
    final nextEntries = _allEntriesBuffer.sublist(
      start,
      end > _allEntriesBuffer.length ? _allEntriesBuffer.length : end,
    );
    await _prefetchThumbnails(nextEntries); // 追加分をプリフェッチ
    setState(() {
      allImageEntries.addAll(nextEntries);
      _currentPage++;
      _isLoading = false;
      if (allImageEntries.length >= _allEntriesBuffer.length) {
        _hasMore = false;
      }
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
        final cacheManager = LimitedCacheManager();
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
            gaplessPlayback: false, // メモリ解放しやすく
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
    return Stack(
      children: [
        Scrollbar(
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
        ),
        if (_isLoading && allImageEntries.isNotEmpty)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
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
