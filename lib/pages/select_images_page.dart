import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      await PhotoManager.openSetting();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
    if (albums.isEmpty) return;

    final recentAlbum = albums.first;
    final recentAssets = await recentAlbum.getAssetListPaged(page: 0, size: 200);

    // 缓存缩略图，加速 UI
    final thumbs = await Future.wait(
      recentAssets.map((e) => e.thumbnailDataWithSize(const ThumbnailSize(200, 200))),
    );

    // 一次 setState，全部更新
    setState(() {
      _assets = recentAssets;
      _thumbs = thumbs;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    final id = asset.id;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < widget.maxSelection) {
        _selectedIds.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('最多只能选择 ${widget.maxSelection} 张图片')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择图片'),
        actions: [
          TextButton(
            onPressed: hasSelection ? _onConfirmPressed : null,
            child: Text(
              '确定 (${_selectedIds.length}/${widget.maxSelection})',
              style: TextStyle(color: hasSelection ? Colors.blue : Colors.grey),
            ),
          ),
        ],
      ),
      body: _assets.isEmpty
          ? const Center(child: Text('正在加载图片...'))
          : AssetGridView(
        assets: _assets,
        thumbs: _thumbs,         // 传入缩略图缓存
        selectedIds: _selectedIds,
        onTap: _toggleSelection,
      ),
    );
  }
}
