import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class AssetGridView extends StatefulWidget {
  final List<AssetEntity> assets;
  final ValueNotifier<Set<String>> selectedIds;
  final ValueChanged<AssetEntity> onToggle;

  const AssetGridView({
    super.key,
    required this.assets,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<AssetGridView> createState() => _AssetGridViewState();
}

class _AssetGridViewState extends State<AssetGridView> {
  final Map<String, Uint8List> _thumbCache = {};

  Future<Uint8List?> _loadThumb(AssetEntity asset) async {
    if (_thumbCache.containsKey(asset.id)) {
      return _thumbCache[asset.id];
    }
    final data = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    if (data != null) {
      _thumbCache[asset.id] = data;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      itemCount: widget.assets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) {
        final asset = widget.assets[index];
        return FutureBuilder<Uint8List?>(
          future: _loadThumb(asset),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ColoredBox(
                color: Color(0xFFF0F0F0),
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Icon(Icons.error));
            }

            return _AssetTile(
              asset: asset,
              thumbBytes: snapshot.data!,
              selectedIds: widget.selectedIds,
              onTap: widget.onToggle,
            );
          },
        );
      },
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetEntity asset;
  final Uint8List thumbBytes;
  final ValueNotifier<Set<String>> selectedIds;
  final ValueChanged<AssetEntity> onTap;

  const _AssetTile({
    required this.asset,
    required this.thumbBytes,
    required this.selectedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片永不重绘
          Image.memory(
            thumbBytes,
            fit: BoxFit.cover,
          ),
          // 仅重绘勾选部分，局部刷新
          ValueListenableBuilder<Set<String>>(
            valueListenable: selectedIds,
            builder: (_, selected, __) {
              final isSelected = selected.contains(asset.id);
              return AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 90),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, right: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
