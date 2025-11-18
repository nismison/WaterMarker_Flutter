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

  // 这里存的是 asset.id 集合
  late final ValueNotifier<Set<String>> _selectedIds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = ValueNotifier<Set<String>>({});
    _loadAssets();
  }

  @override
  void dispose() {
    _selectedIds.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;

    if (!result.isAuth) {
      await PhotoManager.openSetting();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) {
      setState(() {
        _assets = [];
        _isLoading = false;
      });
      return;
    }

    // ✅ 这里改为命名参数
    final List<AssetEntity> assets = await paths.first.getAssetListPaged(
      page: 0,
      size: 200,
    );

    // 预选：把 preSelectedPaths（文件路径）映射为对应的 asset.id
    final Set<String> initialIds = {};
    final Set<String> prePathSet = widget.preSelectedPaths.toSet();
    for (final asset in assets) {
      final file = await asset.file;
      if (file != null && prePathSet.contains(file.path)) {
        initialIds.add(asset.id);
      }
    }

    if (!mounted) return;
    setState(() {
      _assets = assets;
      _isLoading = false;
      _selectedIds.value = initialIds;
    });
  }

  void _toggleSelect(AssetEntity asset) {
    final current = Set<String>.from(_selectedIds.value);
    if (current.contains(asset.id)) {
      current.remove(asset.id);
    } else {
      if (current.length >= widget.maxSelection) {
        return;
      }
      current.add(asset.id);
    }
    _selectedIds.value = current; // 不要调用 setState
  }

  /// 确定选择：把选中的 asset.id 转为路径列表再返回
  Future<void> _onConfirm() async {
    final ids = _selectedIds.value;
    final List<String> paths = [];
    for (final asset in _assets) {
      if (ids.contains(asset.id)) {
        final file = await asset.file;
        if (file != null && file.path.isNotEmpty) {
          paths.add(file.path);
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 标题用 ValueListenableBuilder 包裹，只更新标题文本
        title: ValueListenableBuilder<Set<String>>(
          valueListenable: _selectedIds,
          builder: (_, selected, _) {
            return Text('选择图片 (${selected.length}/${widget.maxSelection})');
          },
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedIds,
            builder: (_, selected, _) {
              if (selected.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: _onConfirm,
                child: const Text(
                  '确定',
                  style: TextStyle(
                    color: Colors.blue, // 蓝色字体
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AssetGridView(
              key: const ValueKey("grid"),
              assets: _assets,
              selectedIds: _selectedIds, // 直接传入
              onToggle: _toggleSelect,
            ),
    );
  }
}
