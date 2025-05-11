import 'package:flutter/material.dart';
import 'full_screen_image.dart';

class ImageGridScreen extends StatelessWidget {
  final String folderPath;

  const ImageGridScreen({super.key, required this.folderPath});

  @override
  Widget build(BuildContext context) {
    // 仮の画像リスト
    final images = List.generate(10, (index) => 'Image $index');

    return Scaffold(
      appBar: AppBar(title: Text(folderPath)),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FullScreenImage(imagePath: images[index]),
                ),
              );
            },
            child: GridTile(
              child: Container(
                color: Colors.grey,
                child: Center(
                  child: Text(
                    images[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
