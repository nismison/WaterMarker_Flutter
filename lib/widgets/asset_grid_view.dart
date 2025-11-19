import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:forui/assets.dart';

class AssetGridView extends StatefulWidget {
  final List<String> selectedIds;
  final int maxSelection;
  final void Function(AssetEntity asset) onPreview;
  final void Function(AssetEntity asset) onToggleSelect;

  const AssetGridView({
    super.key,
    required this.selectedIds,
    required this.maxSelection,
    required this.onPreview,
    required this.onToggleSelect,
  });

  @override
  State<AssetGridView> createState() => _AssetGridViewState();
}

class _AssetGridViewState extends State<AssetGridView> {
  final List<AssetEntity> _assets = [];
  final Map<String, Uint8List?> _thumbCache = {};

  int? _lastDragIndex;

  AssetPathEntity? _gallery;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  static const int pageSize = 120;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return;

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (paths.isEmpty) return;

    _gallery = paths.first;
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_hasMore) return;
    _loading = true;

    final list = await _gallery!.getAssetListPaged(page: _page, size: pageSize);

    if (list.isEmpty) {
      _hasMore = false;
    } else {
      _assets.addAll(list);
      _page++;
    }
    _loading = false;

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

  int? _getIndexFromOffset(Offset position, Size gridSize) {
    final itemWidth = gridSize.width / 3;
    final col = position.dx ~/ itemWidth;
    final row = position.dy ~/ itemWidth;
    final index = row * 3 + col;
    if (index >= 0 && index < _assets.length) {
      return index;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final Size gridSize = constraints.biggest;

        return RawGestureDetector(
          gestures: {
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(() => HorizontalDragGestureRecognizer(), (
                  HorizontalDragGestureRecognizer instance,
                ) {
                  instance.onStart = (details) {};

                  instance.onUpdate = (details) {
                    final pos = details.localPosition;
                    final index = _getIndexFromOffset(pos, gridSize);
                    if (index != null && index != _lastDragIndex) {
                      _lastDragIndex = index;

                      final asset = _assets[index];
                      final already = widget.selectedIds.contains(asset.id);
                      final canSelect =
                          already ||
                          widget.selectedIds.length < widget.maxSelection;

                      if (canSelect) {
                        widget.onToggleSelect(asset);
                      }
                    }
                  };

                  instance.onEnd = (_) {
                    _lastDragIndex = null;
                  };
                }),
          },

          child: NotificationListener<ScrollNotification>(
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

                // 选中项永远允许点击（用于取消）
                // 未选项在达到上限后禁用
                final bool canSelect =
                    isSelected ||
                    widget.selectedIds.length < widget.maxSelection;

                return AnimatedScale(
                  scale: isSelected ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 缩略图 + 预览
                      FutureBuilder<Uint8List?>(
                        future: _loadThumb(asset),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return Container(color: Colors.grey.shade200);
                          }

                          // 再取 filePath（为 Hero tag 服务）
                          return FutureBuilder<File?>(
                            future: asset.file,
                            builder: (_, fileSnap) {
                              if (!fileSnap.hasData) {
                                // 没有 filePath 时先显示 thumbnail
                                return Image.memory(
                                  snap.data!,
                                  fit: BoxFit.cover,
                                );
                              }

                              final filePath = fileSnap.data!.path;

                              return GestureDetector(
                                onTap: () {
                                  widget.onPreview(asset); // 仍然只传一个参数 ← ← ← 核心
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Hero(
                                    tag: "select_page_$filePath",
                                    child: Image.memory(
                                      snap.data!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // 半透明遮罩
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),

                      // 勾选框（完全阻止事件穿透）
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque, // ★ 不穿透
                          onTap: () {
                            if (canSelect) widget.onToggleSelect(asset);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
