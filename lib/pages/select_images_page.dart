import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/asset_grid_view.dart';
import 'advanced_image_preview_page.dart';

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
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _initPreSelected();
  }

  /// 将 preSelectedPaths（filePath）映射到 asset.id
  Future<void> _initPreSelected() async {
    if (widget.preSelectedPaths.isEmpty) return;

    final List<String> filePaths = widget.preSelectedPaths;
    final List<String> selectedIds = [];

    // 获取最近相册（“所有图片”）
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    if (albums.isEmpty) return;
    final album = albums.first;

    // 每个 filePath 并发查找
    final futures = filePaths.map((filePath) async {
      String? matchedId;

      int page = 0;
      const int pageSize = 100;

      while (true) {
        final List<AssetEntity> assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );

        if (assets.isEmpty) break;

        for (final asset in assets) {
          final file = await asset.file;
          if (file != null && file.path == filePath) {
            matchedId = asset.id;
            break;
          }
        }

        if (matchedId != null) break;
        page++;
      }

      if (matchedId != null) {
        selectedIds.add(matchedId);
      }
    });

    await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      _selectedIds.addAll(selectedIds);
    });
  }

  /// 点击右上角勾选框
  void _toggleSelection(AssetEntity asset) {
    final id = asset.id;

    setState(() {
      if (_selectedIds.contains(id)) {
        // 已选 → 允许取消
        _selectedIds.remove(id);
      } else {
        // 未选 → 但已经达到上限，直接禁止
        if (_selectedIds.length >= widget.maxSelection) {
          return; // 直接阻止，不提示、不报错
        }
        _selectedIds.add(id);
      }
    });
  }

  /// 点击图片 → 预览
  void _previewImage(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;

    showImagePreview(
      context,
      imagePath: file.path,
      useHero: true,
      tagPrefix: 'select_page',
    );
  }

  /// 点击确定按钮 → 返回 filePaths
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
        title: Row(children: const [Text('选择图片')]),
        prefixes: [FHeaderAction.back(onPress: () => Navigator.pop(context))],
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

      child: AssetGridView(
        selectedIds: _selectedIds,
        maxSelection: widget.maxSelection,
        onPreview: _previewImage,
        onToggleSelect: _toggleSelection,
      ),
    );
  }
}
