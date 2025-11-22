import 'package:flutter/material.dart';
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
  AssetPathEntity? _mainAlbum;

  @override
  void initState() {
    super.initState();
    _initGallery();
  }

  // ============================================================
  // ★ Step1：扫描相册（一次）
  // ★ Step2：定位主相册（isAll）
  // ★ Step3：处理预选择路径 → assetId
  // ============================================================
  Future<void> _initGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);

    if (albums.isEmpty) return;

    // 找主相册（图片全部集合）
    AssetPathEntity? mainAlbum;
    for (final a in albums) {
      if (a.isAll) {
        mainAlbum = a;
        break;
      }
    }
    _mainAlbum = mainAlbum ?? albums.first;

    if (widget.preSelectedPaths.isNotEmpty) {
      await _initPreSelected(_mainAlbum!);
    }

    if (mounted) setState(() {});
  }

  // ============================================================
  // ★ 根据 filePath 查找 asset.id（支持预选）
  // ============================================================
  Future<void> _initPreSelected(AssetPathEntity album) async {
    final List<String> resultIds = [];

    for (final fp in widget.preSelectedPaths) {
      bool found = false;

      int page = 0;
      const int pageSize = 100;

      while (!found) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        if (assets.isEmpty) break;

        for (final a in assets) {
          final f = await a.file;
          if (f != null && f.path == fp) {
            resultIds.add(a.id);
            found = true;
            break;
          }
        }
        page++;
      }
    }

    _selectedIds.addAll(resultIds);
  }

  // ============================================================
  // ★ 切换选择
  // ============================================================
  void _onToggleSelect(AssetEntity asset) {
    final id = asset.id;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < widget.maxSelection) {
          _selectedIds.add(id);
        }
      }
    });
  }

  // ============================================================
  // ★ 图片预览
  // ============================================================
  void _onPreview(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;

    showImagePreview(
      context,
      imagePath: file.path,
      useHero: true,
      tagPrefix: 'select_page', // 这里是关键，和 Hero tag 前缀要一致
    );
  }

  // ============================================================
  // ★ 返回 filePath 列表
  // ============================================================
  Future<void> _onConfirm() async {
    final List<String> paths = [];
    for (final id in _selectedIds) {
      final entity = await AssetEntity.fromId(id);
      final file = await entity?.file;
      if (file != null) paths.add(file.path);
    }
    Navigator.pop(context, paths);
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _mainAlbum != null;
    final hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("选择图片"),
        actions: [
          TextButton(
            onPressed: hasSelection ? _onConfirm : null,
            child: Text(
              "确定 (${_selectedIds.length}/${widget.maxSelection})",
              style: TextStyle(
                color: hasSelection ? Colors.blue : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: loaded
          ? AssetGridView(
              album: _mainAlbum!,
              // ★ 只传一次 album
              selectedIds: _selectedIds,
              maxSelection: widget.maxSelection,
              onPreview: _onPreview,
              onToggleSelect: _onToggleSelect,
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
