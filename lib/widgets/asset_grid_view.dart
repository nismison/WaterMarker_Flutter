import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AssetGridView extends StatelessWidget {
  final List<AssetEntity> assets;
  final List<Uint8List?> thumbs;   // 缓存缩略图，加入参数
  final List<String> selectedIds;
  final void Function(AssetEntity) onTap;

  const AssetGridView({
    super.key,
    required this.assets,
    required this.thumbs,
    required this.selectedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final thumb = thumbs[index];
        final isSelected = selectedIds.contains(asset.id);

        return GestureDetector(
          onTap: () => onTap(asset),
          child: Stack(
            children: [
              Positioned.fill(
                child: thumb == null
                    ? Container(color: Colors.grey.shade200)
                    : Image.memory(thumb, fit: BoxFit.cover),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
