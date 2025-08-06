import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../platform/file_entry.dart';
import '../provider/current_image_index_provider.dart';

class FullScreenImage extends ConsumerStatefulWidget {
  const FullScreenImage({super.key, required this.fileEntries});

  final List<FileEntry> fileEntries;

  @override
  ConsumerState<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends ConsumerState<FullScreenImage> {
  late PageController _pageController;
  final DefaultCacheManager cacheManager = DefaultCacheManager();
  final Map<int, Future<Uint8List>> _imageFutures = <int, Future<Uint8List>>{};
  Uint8List? _lastImageBytes;

  @override
  void initState() {
    super.initState();
    final int index = ref.read(currentImageIndexProvider);
    _pageController = PageController(initialPage: index);
    _prefetchAround(index);
  }

  void _prefetchAround(int index) {
    for (final int i in <int>[index - 1, index, index + 1]) {
      if (i >= 0 && i < widget.fileEntries.length) {
        _imageFutures[i] ??= _getImageBytesWithCache(widget.fileEntries[i]);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List> _getImageBytesWithCache(FileEntry fileEntry) async {
    final String imagePath = fileEntry.path;
    final FileInfo? cachedFile = await cacheManager.getFileFromCache(imagePath);
    if (cachedFile != null && await cachedFile.file.exists()) {
      return cachedFile.file.readAsBytes();
    }
    final Uint8List bytes = await fileEntry.readAsBytes();
    await cacheManager.putFile(imagePath, bytes);
    return bytes;
  }

  Widget getImageSync(FileEntry fileEntry, int index) {
    final String imagePath = fileEntry.path;
    _imageFutures[index] ??= _getImageBytesWithCache(fileEntry);

    Widget buildChild(AsyncSnapshot<Uint8List> snapshot) {
      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
        _lastImageBytes = snapshot.data;
        return _buildPhotoView(snapshot.data!, imagePath, index);
      } else if (snapshot.hasError) {
        return const Icon(Icons.error, color: Colors.red);
      } else if (snapshot.hasData) {
        return _buildPhotoView(snapshot.data!, imagePath, index, isPlaceholder: true);
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }

    return FutureBuilder<Uint8List>(
      future: _imageFutures[index],
      initialData: _lastImageBytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        final Widget child = buildChild(snapshot);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
            );
          },
          child:
              child is PhotoView
                  ? KeyedSubtree(key: ValueKey<String>(imagePath), child: child)
                  : child,
        );
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
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
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
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
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
    final int currentIndex = ref.watch(currentImageIndexProvider);
    return Scaffold(
      appBar: AppBar(title: Text('${currentIndex + 1} / ${widget.fileEntries.length}')),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.fileEntries.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (int index) {
          ref.read(currentImageIndexProvider.notifier).index = index;
          _prefetchAround(index);
        },
        itemBuilder: (BuildContext context, int index) {
          return Center(child: getImageSync(widget.fileEntries[index], index));
        },
      ),
    );
  }
}
