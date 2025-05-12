import 'package:flutter/material.dart';
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
  List<String> allImages = [];
  List<String> displayedImages = [];
  int currentIndex = 0;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadImages() {
    final images =
        Directory(widget.folderPath)
            .listSync()
            .where(
              (file) =>
                  file is File &&
                  (file.path.toLowerCase().endsWith('.png') ||
                      file.path.toLowerCase().endsWith('.jpg') ||
                      file.path.toLowerCase().endsWith('.jpeg') ||
                      file.path.toLowerCase().endsWith('.gif')),
            )
            .map((file) => file.path)
            .toList();
    setState(() {
      allImages = images;
      displayedImages = images.take(pageSize).toList();
      currentIndex = displayedImages.length;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading) {
      _loadMoreImages();
    }
  }

  void _loadMoreImages() {
    if (currentIndex >= allImages.length) return;
    setState(() {
      isLoading = true;
    });
    final nextIndex = (currentIndex + pageSize).clamp(0, allImages.length);
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        displayedImages.addAll(allImages.getRange(currentIndex, nextIndex));
        currentIndex = nextIndex;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderPath)),
      body:
          allImages.isEmpty
              ? const Center(child: Text('画像が見つかりません'))
              : NotificationListener<ScrollNotification>(
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
                  itemCount: displayedImages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= displayedImages.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FullScreenImage(
                                  images: displayedImages,
                                  initialIndex: index,
                                ),
                          ),
                        );
                      },
                      child: GridTile(
                        footer: Container(
                          color: Colors.black54,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              displayedImages[index]
                                  .split(Platform.pathSeparator)
                                  .last,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.file(
                            File(displayedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
