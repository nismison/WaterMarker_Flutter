// lib/pages/watermark_preview_page.dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'advanced_image_preview_page.dart';
import 'image_preview_page.dart';

class WatermarkPreviewPage extends StatelessWidget {
  final List<String> imagePaths;

  const WatermarkPreviewPage({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("水印预览")),
        body: const Center(child: Text("没有可预览的图片")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("水印预览"),
        actions: [
          IconButton(
            onPressed: () {
              // 可扩展批量上传、保存操作
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("批量上传功能未实现")));
            },
            icon: const Icon(Icons.cloud_upload),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: imagePaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 每行3张
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, i) {
          final path = imagePaths[i];
          return GestureDetector(
            onTap: () => {
              showImagePreview(
                context,
                imagePath: path,
                useHero: true,
                fadeDuration: Duration(milliseconds: 150),
                imageList: imagePaths,
              ),
            },
            child: Hero(
              tag: path,
              child: Image.file(File(path), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _showPreview(BuildContext context, String path) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ImagePreviewPage(imagePath: path),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
