import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imagePath;

  const FullScreenImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('画像表示')),
      body: Center(child: Image.asset(imagePath, fit: BoxFit.contain)),
    );
  }
}
