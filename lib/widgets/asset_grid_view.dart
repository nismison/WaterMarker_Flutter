import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:forui/assets.dart';
import 'package:photo_manager/photo_manager.dart';

class AssetGridView extends StatefulWidget {
  final List<String> selectedIds;
  final int maxSelection;
  final void Function(AssetEntity) onPreview;
  final void Function(AssetEntity) onSelect;

  const AssetGridView({
    super.key,
    required this.selectedIds,
    required this.maxSelection,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  State<AssetGridView> createState() => _AssetGridViewState();
}

class _AssetGridViewState extends State<AssetGridView> {
  final List<AssetEntity> _assets = [];
  final Map<String, Uint8List?> _thumbCache = {};

  AssetPathEntity? _gallery;
  bool _isLoading = false;
  bool _hasMore = true;

  static const int _pageSize = 120;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initGallery();
  }

  Future<void> _initGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return;

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    if (paths.isEmpty) return;

    _gallery = paths.first;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore || _gallery == null) return;
    _isLoading = true;

    final newAssets = await _gallery!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (newAssets.isEmpty) {
      _hasMore = false;
    } else {
      _assets.addAll(newAssets);
      _currentPage++;
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<Uint8List?> _loadThumb(AssetEntity asset) async {
    if (_thumbCache.containsKey(asset.id)) return _thumbCache[asset.id];

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
    );

    _thumbCache[asset.id] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
          _loadNextPage();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _assets.length,
        itemBuilder: (_, i) {
          final asset = _assets[i];
          final isSelected = widget.selectedIds.contains(asset.id);
          // 选中项永远能点击（用于取消）
          // 未选项 → 达到上限后禁用
          final bool canSelect =
              isSelected || widget.selectedIds.length < widget.maxSelection;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 图片区域
              Positioned.fill(
                child: FutureBuilder<Uint8List?>(
                  future: _loadThumb(asset),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return Container(color: Colors.grey.shade200);
                    }

                    return FutureBuilder<File?>(
                      future: asset.file,
                      builder: (_, fileSnap) {
                        if (!fileSnap.hasData) {
                          // 文件路径还没拿到 → 不放 Hero，避免 tag 为 null
                          return GestureDetector(
                            onTap: () => widget.onPreview(asset),
                            child: Image.memory(snap.data!, fit: BoxFit.cover),
                          );
                        }

                        final filePath = fileSnap.data!.path;

                        return GestureDetector(
                          onTap: () => widget.onPreview(asset),
                          child: Hero(
                            tag: "select_page_$filePath", // 使用文件路径作为Hero tag
                            child: Image.memory(snap.data!, fit: BoxFit.cover),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // 右上角选择框
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: canSelect ? () => widget.onSelect(asset) : null,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 1.2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            FIcons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
