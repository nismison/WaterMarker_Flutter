import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/asset_grid_view.dart';

class SelectImagesPage extends StatefulWidget {
  final int maxSelection;
  final List<String> preSelectedPaths;

  const SelectImagesPage({
    super.key,
    this.maxSelection = 9,
    this.preSelectedPaths = const [],
  });

  @override
  State<SelectImagesPage> createState() => _SelectImagesPageState();
}

class _SelectImagesPageState extends State<SelectImagesPage> {
  List<AssetEntity> _assets = [];
  List<Uint8List?> _thumbs = []; // 缓存缩略图
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (albums.isEmpty) return;

    final recentAlbum = albums.first;
    final recentAssets = await recentAlbum.getAssetListPaged(
      page: 0,
      size: 200,
    );

    // 缓存缩略图，加速 UI
    final thumbs = await Future.wait(
      recentAssets.map(
        (e) => e.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      ),
    );

    // 一次 setState，全部更新
    setState(() {
      _assets = recentAssets;
      _thumbs = thumbs;
    });
  }

  /// 点击某一张缩略图时切换选中状态
  void _toggleSelection(AssetEntity asset) {
    final id = asset.id;

    setState(() {
      if (_selectedIds.contains(id)) {
        // 如果已存在，取消选择
        _selectedIds.remove(id);
      } else {
        // 判断是否超过最大选择数
        if (_selectedIds.length >= widget.maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('最多只能选择 ${widget.maxSelection} 张图片')),
          );
          return;
        }

        // 按点击顺序加入
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _onConfirmPressed() async {
    final paths = <String>[];
    for (final id in _selectedIds) {
      final entity = await AssetEntity.fromId(id);
      final file = await entity?.file;
      if (file != null) {
        paths.add(file.path);
      }
    }
    Navigator.pop(context, paths);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIds.isNotEmpty;

    return FScaffold(
      header: FHeader.nested(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text('选择图片')],
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () {
              Navigator.pop(context);
            },
          ),
        ],
        suffixes: [
          TextButton(
            onPressed: hasSelection ? _onConfirmPressed : null,
            child: Text(
              '确定 (${_selectedIds.length}/${widget.maxSelection})',
              style: TextStyle(color: hasSelection ? Colors.blue : Colors.grey),
            ),
          ),
        ],
      ),
      child: _assets.isEmpty
          ? const Center(child: Text('正在加载图片...'))
          : AssetGridView(
              assets: _assets,
              thumbs: _thumbs, // 传入缩略图缓存
              selectedIds: _selectedIds,
              onTap: _toggleSelection,
            ),
    );
  }
}
