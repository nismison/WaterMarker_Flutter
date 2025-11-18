import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:forui/assets.dart';
import 'package:water_marker_test2/utils/loading_manager.dart';

import '../utils/storage_util.dart';
import 'advanced_image_preview_page.dart';

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
            onPressed: () async {
              final loading = GlobalLoading();

              try {
                loading.show(context, text: "正在保存图片...");

                final paths = await StorageUtil.saveImages(imagePaths);

                debugPrint("成功保存到：$paths");
                Fluttertoast.showToast(msg: "保存成功", backgroundColor: Colors.green);
              } catch (e) {
                Fluttertoast.showToast(msg: "保存失败：$e", backgroundColor: Colors.red);
              } finally {
                loading.hide();
              }
            },
            icon: const Icon(FIcons.saveAll),
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
}
