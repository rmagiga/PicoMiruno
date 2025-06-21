import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mygallery/platform/image_service.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const FullScreenImage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late PageController _pageController;
  late int _currentIndex;
  final _imageService = ImageServiceFactory.create();
  final Map<String, Uint8List> _memoryImageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List> _getImageBytesWithCache(String imagePath) async {
    // メモリキャッシュ優先
    if (_memoryImageCache.containsKey(imagePath)) {
      return _memoryImageCache[imagePath]!;
    }
    final cacheManager = DefaultCacheManager();
    final cachedFile = await cacheManager.getFileFromCache(imagePath);
    if (cachedFile != null && await cachedFile.file.exists()) {
      final bytes = await cachedFile.file.readAsBytes();
      _memoryImageCache[imagePath] = bytes;
      return bytes;
    }
    final bytes = await _imageService.getImageByte(imagePath);
    await cacheManager.putFile(imagePath, bytes);
    _memoryImageCache[imagePath] = bytes;
    return bytes;
  }

  // flutter_cache_managerの利用をやめ、ImageServiceのgetImageByteを使う
  Widget getImageSync(String imagePath, int index) {
    if (_memoryImageCache.containsKey(imagePath)) {
      return _buildPhotoView(_memoryImageCache[imagePath]!, imagePath, index);
    }
    return FutureBuilder<Uint8List>(
      future: _getImageBytesWithCache(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return _buildPhotoView(snapshot.data!, imagePath, index);
        } else if (snapshot.hasError) {
          return const Icon(Icons.error, color: Colors.red);
        } else {
          // 前の画像があればそれを一時的に表示
          if (_memoryImageCache.isNotEmpty) {
            final prev = _memoryImageCache.values.last;
            return _buildPhotoView(prev, imagePath, index, isPlaceholder: true);
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
      },
    );
  }

  Widget _buildPhotoView(
    Uint8List bytes,
    String imagePath,
    int index, {
    bool isPlaceholder = false,
  }) {
    return Stack(
      children: [
        PhotoView(
          imageProvider: MemoryImage(bytes),
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 5.0,
          heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
          gestureDetectorBehavior: HitTestBehavior.translucent,
          enablePanAlways: true,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          enableRotation: true,
        ),
        // 左端スワイプ
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 0) {
                if (index > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                }
              }
            },
            onTapUp: (_) {
              if (index > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              }
            },
            child: const SizedBox(width: 40, height: double.infinity),
          ),
        ),
        // 右端スワイプ
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                if (index < widget.imagePaths.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                }
              }
            },
            onTapUp: (_) {
              if (index < widget.imagePaths.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              }
            },
            child: const SizedBox(width: 40, height: double.infinity),
          ),
        ),
        if (isPlaceholder)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(child: getImageSync(widget.imagePaths[index], index));
        },
      ),
    );
  }
}
