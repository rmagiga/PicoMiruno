import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';

import 'platform/file_entry.dart';

class FullScreenImage extends StatefulWidget {
  const FullScreenImage({
    super.key,
    required this.fileEntries,
    required this.initialIndex,
  });

  final List<FileEntry> fileEntries;
  final int initialIndex;

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late PageController _pageController;
  late int _currentIndex;
  final DefaultCacheManager cacheManager = DefaultCacheManager();

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

  Future<Uint8List> _getImageBytesWithCache(FileEntry fileEntry) async {
    // メモリキャッシュ優先
    final String imagePath = fileEntry.path;
    final FileInfo? cachedFile = await cacheManager.getFileFromCache(imagePath);
    if (cachedFile != null && await cachedFile.file.exists()) {
      return cachedFile.file.readAsBytes();
    }
    final Uint8List bytes = await fileEntry.readAsBytes();
    await cacheManager.putFile(imagePath, bytes);
    return bytes;
  }

  // flutter_cache_managerの利用をやめ、ImageServiceのgetImageByteを使う
  Widget getImageSync(FileEntry fileEntry, int index) {
    final String imagePath = fileEntry.path;

    return FutureBuilder<Uint8List>(
      future: _getImageBytesWithCache(fileEntry),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return _buildPhotoView(snapshot.data!, imagePath, index);
        } else if (snapshot.hasError) {
          return const Icon(Icons.error, color: Colors.red);
        }
        // Show a loading indicator while waiting for the image
        return const Center(child: CircularProgressIndicator());
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
      children: <Widget>[
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
            onHorizontalDragEnd: (DragEndDetails details) {
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
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                if (index < widget.fileEntries.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                }
              }
            },
            onTapUp: (_) {
              if (index < widget.fileEntries.length - 1) {
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
        title: Text('${_currentIndex + 1} / ${widget.fileEntries.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.fileEntries.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (BuildContext context, int index) {
          return Center(child: getImageSync(widget.fileEntries[index], index));
        },
      ),
    );
  }
}
