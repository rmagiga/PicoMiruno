import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mygallery/platform/image_service.dart';

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

  // フルスクリーン用画像キャッシュ（LRU方式）
  static const int maxCacheSize = 20;
  final Map<String, Uint8List> _imageCache = {};
  final List<String> _cacheOrder = [];

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

  Widget getImageSync(String imagePath) {
    if (_imageCache.containsKey(imagePath)) {
      return Image.memory(
        _imageCache[imagePath]!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return FutureBuilder<Uint8List>(
      future: _imageService.getImageByte(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
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

  void _addToCache(String key, Uint8List value) {
    if (_imageCache.containsKey(key)) {
      _cacheOrder.remove(key);
    }
    _imageCache[key] = value;
    _cacheOrder.add(key);
    if (_imageCache.length > maxCacheSize) {
      final removeKey = _cacheOrder.removeAt(0);
      _imageCache.remove(removeKey);
      // FlutterのimageCacheからも削除
      imageCache.clear();
    }
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
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: getImageSync(widget.imagePaths[index]),
            ),
          );
        },
      ),
    );
  }
}
