import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:forui/assets.dart';

class AssetGridView extends StatefulWidget {
  final AssetPathEntity album; // ★ 直接接收主相册
  final List<String> selectedIds;
  final int maxSelection;
  final void Function(AssetEntity asset) onPreview;
  final void Function(AssetEntity asset) onToggleSelect;

  const AssetGridView({
    super.key,
    required this.album,
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

  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  static const int pageSize = 120;
  int? _lastDragIndex;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  // ============================================================
  // ★ 分页加载（不再扫描相册）
  // ============================================================
  Future<void> _loadNextPage() async {
    if (_loading || !_hasMore) return;
    _loading = true;

    final list = await widget.album.getAssetListPaged(
      page: _page,
      size: pageSize,
    );

    if (list.isEmpty) {
      _hasMore = false;
    } else {
      _assets.addAll(list);
      _page++;
    }

    _loading = false;
    if (mounted) setState(() {});
  }

  Future<Uint8List?> _thumb(AssetEntity asset) async {
    if (_thumbCache.containsKey(asset.id)) return _thumbCache[asset.id];
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
    );
    _thumbCache[asset.id] = data;
    return data;
  }

  int? _indexFromOffset(Offset pos, Size gridSize) {
    final w = gridSize.width / 3;
    final col = pos.dx ~/ w;
    final row = pos.dy ~/ w;
    final index = row * 3 + col;
    return (index >= 0 && index < _assets.length) ? index : null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;

        return RawGestureDetector(
          gestures: {
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(() => HorizontalDragGestureRecognizer(), (
                  HorizontalDragGestureRecognizer instance,
                ) {
                  instance
                    ..onStart = (_) {}
                    ..onUpdate = (details) {
                      final pos = details.localPosition;
                      final index = _indexFromOffset(pos, size);

                      if (index != null && index != _lastDragIndex) {
                        _lastDragIndex = index;

                        final asset = _assets[index];
                        final already = widget.selectedIds.contains(asset.id);
                        final allowed =
                            already ||
                            widget.selectedIds.length < widget.maxSelection;

                        if (allowed) {
                          widget.onToggleSelect(asset);
                        }
                      }
                    }
                    ..onEnd = (_) {
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
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _assets.length,
              itemBuilder: (_, i) {
                final asset = _assets[i];
                final selected = widget.selectedIds.contains(asset.id);

                final allowed =
                    selected || widget.selectedIds.length < widget.maxSelection;

                return AnimatedScale(
                  scale: selected ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Stack(
                    fit: StackFit.expand, // ★ 关键：让子内容填满 1:1 格子
                    children: [
                      // 缩略图 + Hero + 点击预览
                      FutureBuilder<Uint8List?>(
                        future: _thumb(asset),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return Container(color: Colors.grey.shade200);
                          }
                          final bytes = snap.data!;

                          // 这里再拿一次 file 只是为了 Hero tag 和预览的一致性
                          return FutureBuilder<File?>(
                            future: asset.file,
                            builder: (_, fileSnap) {
                              final file = fileSnap.data;
                              // 如果拿不到 filePath，就不用 Hero，只展示缩略图
                              final String? heroTag = file == null
                                  ? null
                                  : 'select_page_${file.path}';

                              Widget image = Image.memory(
                                bytes,
                                fit: BoxFit.cover,
                              );

                              if (heroTag != null) {
                                image = Hero(tag: heroTag, child: image);
                              }

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onPreview(asset),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: image,
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // 选中遮罩
                      if (selected)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),

                      // 勾选圆点
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              allowed ? widget.onToggleSelect(asset) : null,
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: selected ? Colors.blue : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? Colors.blue : Colors.grey,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      FIcons.check,
                                      color: Colors.white,
                                      size: 14,
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
