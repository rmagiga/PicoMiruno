import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mygallery/platform/image_service.dart';
import 'dart:io';
import 'full_screen_image.dart';

class ImageGridScreen extends StatefulWidget {
  final String folderPath;
  const ImageGridScreen({super.key, required this.folderPath});

  @override
  State<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends State<ImageGridScreen> {
  static const int pageSize = 100;
  static const int maxCacheSize = 10000; // サムネイルキャッシュの最大数
  List<String> allImagePaths = [];
  List<String> displayedImagePaths = [];
  int currentIndex = 0;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final _imageService = ImageServiceFactory.create();

  // サムネイルキャッシュ
  final Map<String, Uint8List> _thumbnailCache = {};
  final List<String> _cacheOrder = [];

  @override
  void initState() {
    super.initState();
    _loadImagePaths();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadImagePaths() async {
    List<String> imagePaths = await _imageService.getImages(widget.folderPath);
    setState(() {
      allImagePaths = imagePaths;
      displayedImagePaths = imagePaths.take(pageSize).toList();
      currentIndex = displayedImagePaths.length;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading) {
      _loadMoreImagePaths();
    }
  }

  void _loadMoreImagePaths() {
    if (currentIndex >= allImagePaths.length) return;
    setState(() {
      isLoading = true;
    });
    final nextIndex = (currentIndex + pageSize).clamp(0, allImagePaths.length);
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        displayedImagePaths.addAll(
          allImagePaths.getRange(currentIndex, nextIndex),
        );
        currentIndex = nextIndex;
        isLoading = false;
      });
    });
  }

  Widget _getThumbnailText(int index) {
    return Container(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          displayedImagePaths[index].split(Platform.pathSeparator).last,
          style: const TextStyle(color: Colors.white, fontSize: 12.0),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // サムネイル画像をキャッシュしつつ取得
  Widget getImageSync(String imagePath) {
    if (_thumbnailCache.containsKey(imagePath)) {
      // キャッシュヒット時は即座に表示
      return Image.memory(
        _thumbnailCache[imagePath]!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    // 非同期でサムネイル取得
    return FutureBuilder<Uint8List>(
      future: _imageService.getThumbnailBytes(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // キャッシュに追加（LRU管理）
          _addToCache(imagePath, snapshot.data!);
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

  // LRUキャッシュ追加処理
  void _addToCache(String key, Uint8List value) {
    if (_thumbnailCache.containsKey(key)) {
      _cacheOrder.remove(key);
    }
    _thumbnailCache[key] = value;
    _cacheOrder.add(key);
    if (_thumbnailCache.length > maxCacheSize) {
      final removeKey = _cacheOrder.removeAt(0);
      _thumbnailCache.remove(removeKey);
      // FlutterのimageCacheからも削除
      imageCache.evict(NetworkImage(removeKey), includeLive: true);
    }
  }

  Widget _getThumbnail(int index) {
    return SizedBox(
      width: 80,
      height: 80,
      child: getImageSync(displayedImagePaths[index]),
    );
  }

  Widget _buildEmptyView() {
    return const Center(child: Text('画像が見つかりません'));
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 90, // サムネイルの最大幅を固定（80+余白）
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          childAspectRatio: 1,
        ),
        itemCount: displayedImagePaths.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayedImagePaths.length) {
            return _buildLoadingIndicator();
          }
          return _buildGridTile(index);
        },
      ),
    );
  }

  Widget _buildGridTile(int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullScreenImage(
                  imagePaths: allImagePaths,
                  initialIndex: index,
                ),
          ),
        );
      },
      child: GridTile(
        footer: _getThumbnailText(index),
        child: _getThumbnail(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderPath)),
      body: allImagePaths.isEmpty ? _buildEmptyView() : _buildGridView(),
    );
  }
}
