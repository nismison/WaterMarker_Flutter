// lib/pages/image_preview_page.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  final String imagePath;
  final bool useHero; // 是否使用 Hero 动画

  const ImagePreviewPage({
    super.key,
    required this.imagePath,
    this.useHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.file(
      File(imagePath),
      fit: BoxFit.contain,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("预览"),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: useHero
            ? Hero(tag: imagePath, child: imageWidget)
            : imageWidget,
      ),
    );
  }
}
