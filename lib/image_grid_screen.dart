import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mygallery/platform/file_entry.dart';
import 'full_screen_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:quiver/collection.dart';

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

  // サムネイルのLRUメモリキャッシュ（最大100件）
  final _thumbMemoryCache = LruMap<String, Uint8List>(maximumSize: 100);
  // サムネイル取得Futureのキャッシュ
  final Map<String, Future<Uint8List>> _thumbFutureCache = {};

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
    // 初回で2ページ分ロード
    await _loadNextPage();
    if (_hasMore) {
      await _loadNextPage();
    }
  }

  void _onScroll() {
    if (_scrollController == null || !_hasMore || _isLoading) return;
    if (_scrollController!.position.pixels >=
        _scrollController!.position.maxScrollExtent - 500) {
      // 先読みを早めに
      _loadNextPage();
    }
  }

  // flutter_cache_managerとLRUキャッシュを使ったサムネイル取得
  Widget getImageSync(FileEntry entry) {
    final cacheDir = widget.cacheDir;
    final thumbKey = entry.getThumbnailPath(cacheDir);
    // メモリキャッシュにあれば即返す
    if (_thumbMemoryCache.containsKey(thumbKey)) {
      return Image.memory(
        _thumbMemoryCache[thumbKey]!,
        fit: BoxFit.cover,
        gaplessPlayback: false,
      );
    }
    // Futureをキャッシュしてちらつきを防ぐ
    _thumbFutureCache[thumbKey] ??= () async {
      final cacheManager = LimitedCacheManager();
      final fileInfo = await cacheManager.getFileFromCache(thumbKey);
      Uint8List bytes;
      if (fileInfo != null && await fileInfo.file.exists()) {
        bytes = await fileInfo.file.readAsBytes();
      } else {
        bytes = await entry.thumbnailReadAsBytes(cacheDir);
        await cacheManager.putFile(thumbKey, bytes, fileExtension: 'jpg');
      }
      // メモリキャッシュに追加
      _thumbMemoryCache[thumbKey] = bytes;
      return bytes;
    }();
    return FutureBuilder<Uint8List>(
      future: _thumbFutureCache[thumbKey],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: false,
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error, color: Colors.red);
        } else {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
      },
    );
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
      // メモリキャッシュにも追加
      _thumbMemoryCache[thumbnailPath] = bytes;
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

  Widget _getThumbnail(int index) {
    return SizedBox(
      key: ValueKey(allImageEntries[index].getThumbnailPath(widget.cacheDir)),
      width: 80,
      height: 80,
      child: getImageSync(allImageEntries[index]),
    );
  }

  Widget _buildEmptyView() {
    return const Center(child: Text('画像が見つかりません'));
  }

  Widget _buildGridView() {
    // 画面に必要なサムネイル数を計算
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gridWidth = MediaQuery.of(context).size.width - 16; // padding分
      final gridHeight = MediaQuery.of(context).size.height;
      final crossAxisCount = (gridWidth / 90).floor();
      final mainAxisCount = (gridHeight / 90).ceil();
      final needCount = crossAxisCount * mainAxisCount;
      if (allImageEntries.length < needCount && _hasMore && !_isLoading) {
        _loadNextPage();
      }
    });
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
          key: ValueKey(
            allImageEntries[index].getThumbnailPath(widget.cacheDir),
          ),
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
