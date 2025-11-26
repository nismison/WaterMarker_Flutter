import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:watermarker_v2/widgets/asset_grid_view.dart';
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

  bool _isLoading = true;
  bool _noPermission = false;
  bool _noImages = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initGallery();
  }

  // ============================================================
  // Step1：申请权限
  // Step2：获取相册列表
  // Step3：找到主相册（isAll）
  // Step4：处理预选
  // ============================================================
  Future<void> _initGallery() async {
    setState(() {
      _isLoading = true;
      _noPermission = false;
      _noImages = false;
      _errorMessage = null;
    });

    try {
      final perm = await PhotoManager.requestPermissionExtend();
      debugPrint(
        '[SelectImagesPage] permission: isAuth=${perm.isAuth}, hasAccess=${perm.hasAccess}',
      );

      // 没有任何访问权限：直接提示，无需继续
      if (!perm.isAuth && !perm.hasAccess) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _noPermission = true;
        });
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      debugPrint('[SelectImagesPage] album count = ${albums.length}');

      // 设备里一个图片都没有（或系统图库没扫描到）
      if (albums.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _noImages = true;
        });
        return;
      }

      // 找主相册（所有图片集合）
      AssetPathEntity? mainAlbum;
      for (final a in albums) {
        if (a.isAll) {
          mainAlbum = a;
          break;
        }
      }
      final selectedAlbum = mainAlbum ?? albums.first;
      debugPrint(
        '[SelectImagesPage] use album: '
        'name=${selectedAlbum.name}, id=${selectedAlbum.id}',
      );

      // 预选路径 → assetId
      if (widget.preSelectedPaths.isNotEmpty) {
        await _initPreSelected(selectedAlbum);
        debugPrint(
          '[SelectImagesPage] pre-selected count = ${_selectedIds.length}',
        );
      }

      if (!mounted) return;
      setState(() {
        _mainAlbum = selectedAlbum;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[SelectImagesPage] _initGallery error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载相册失败: $e';
      });
    }
  }

  // ============================================================
  // 根据 filePath 查找 asset.id（支持预选）
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

    _selectedIds
      ..clear()
      ..addAll(resultIds);
  }

  // ============================================================
  // 切换选择
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
  // 图片预览
  // ============================================================
  void _onPreview(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;

    showImagePreview(
      context,
      imagePath: file.path,
      useHero: true,
      tagPrefix: 'select_page', // 要与 Grid 中的 Hero 前缀一致
    );
  }

  // ============================================================
  // 返回 filePath 列表
  // ============================================================
  Future<void> _onConfirm() async {
    final List<String> paths = [];
    for (final id in _selectedIds) {
      final entity = await AssetEntity.fromId(id);
      final file = await entity?.file;
      if (file != null) {
        paths.add(file.path);
      }
    }
    Navigator.pop(context, paths);
  }

  // ============================================================
  // 各种状态 UI
  // ============================================================
  Widget _buildNoPermission() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '无法访问相册',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '请在系统设置中允许本应用访问照片/媒体，否则无法选择图片。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                PhotoManager.openSetting();
              },
              child: const Text('前往设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到任何图片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '当前设备相册中没有可用的图片。\n可以尝试拍一张照片或拷贝几张图片再回来看看。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _initGallery, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIds.isNotEmpty;

    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_noPermission) {
      body = _buildNoPermission();
    } else if (_noImages) {
      body = _buildNoImages();
    } else if (_errorMessage != null) {
      body = _buildError();
    } else if (_mainAlbum != null) {
      body = AssetGridView(
        album: _mainAlbum!,
        selectedIds: _selectedIds,
        maxSelection: widget.maxSelection,
        onPreview: _onPreview,
        onToggleSelect: _onToggleSelect,
      );
    } else {
      // 理论上不应该走到这里，兜底显示空相册提示
      body = _buildNoImages();
    }

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
      body: body,
    );
  }
}
