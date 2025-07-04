import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../infrastructure/cache_manager_image_provider_service.dart';
import '../infrastructure/image_provider_service.dart';
import '../platform/file_entry.dart';
import '../provider/file_entry_list_provider.dart';

class FullScreenImage extends ConsumerStatefulWidget {
  const FullScreenImage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  ConsumerState<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends ConsumerState<FullScreenImage> {
  late PageController _pageController;
  late int _currentIndex;
  final ImageProviderService imageProviderService = CacheManagerImageProviderService();
  final Map<int, Future<Uint8List>> _imageFutures = <int, Future<Uint8List>>{};
  Uint8List? _lastImageBytes;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // 初期表示時に前後画像もプリフェッチ
    _prefetchAround(_currentIndex);
  }

  void _prefetchAround(int index) {
    final List<FileEntry> files = ref.read(fileEntryListProvider);
    for (final int i in <int>[index - 1, index, index + 1]) {
      if (i >= 0 && i < files.length) {
        _imageFutures[i] ??= imageProviderService.getImageBytes(files[i]);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // flutter_cache_managerの利用をやめ、ImageServiceのgetImageByteを使う
  Widget getImageSync(FileEntry fileEntry, int index) {
    final String imagePath = fileEntry.path;
    _imageFutures[index] ??= imageProviderService.getImageBytes(fileEntry);
    return FutureBuilder<Uint8List>(
      future: _imageFutures[index],
      initialData: _lastImageBytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          // 新しい画像データを保持
          _lastImageBytes = snapshot.data;
          child = _buildPhotoView(snapshot.data!, imagePath, index);
        } else if (snapshot.hasError) {
          child = const Icon(Icons.error, color: Colors.red);
        } else if (snapshot.hasData) {
          // 読み込み中は前回画像を表示
          child = _buildPhotoView(snapshot.data!, imagePath, index, isPlaceholder: true);
        } else {
          child = const Center(child: CircularProgressIndicator());
        }
        // AnimatedSwitcherで画像切り替えをなめらかに
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
        // 左端スワイプ
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
        // 右端スワイプ
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                final List<FileEntry> files = ref.read(fileEntryListProvider);
                if (index < files.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                }
              }
            },
            onTapUp: (_) {
              final List<FileEntry> files = ref.read(fileEntryListProvider);
              if (index < files.length - 1) {
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
    final List<FileEntry> files = ref.watch(fileEntryListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('${_currentIndex + 1} / ${files.length}')),
      body: PageView.builder(
        controller: _pageController,
        itemCount: files.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
            _prefetchAround(index); // スワイプ時に前後画像もプリフェッチ
          });
        },
        itemBuilder: (BuildContext context, int index) {
          return Center(child: getImageSync(files[index], index));
        },
      ),
    );
  }
}
