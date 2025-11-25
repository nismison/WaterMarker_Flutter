import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../providers/app_config_provider.dart';
import '../utils/md5_util.dart';
import '../data/local_media_index.dart';
import '../data/sqflite_media_index.dart';
import '../api/upload_api.dart';
import '../utils/device_util.dart';

class ImageSyncService {
  final LocalMediaIndex localIndex;
  final UploadApi uploadApi;
  final bool isUpload;

  String? _deviceModelCache;

  ImageSyncService({
    LocalMediaIndex? localIndex,
    UploadApi? uploadApi,
    bool? isTest,
    bool? isUpload,
  }) : localIndex = localIndex ?? SqfliteMediaIndex(),
       uploadApi = uploadApi ?? UploadApi(),
       isUpload = isUpload ?? true;

  Future<String> _ensureDeviceModel() async {
    if (_deviceModelCache != null) return _deviceModelCache!;
    _deviceModelCache =
        await DeviceUtil.getDeviceModel(); // 这里就是你前面定义的 brand/model 大小写逻辑
    return _deviceModelCache!;
  }

  /// 对外入口：在权限已就绪后调用
  Future<void> syncAllImages(AppConfigProvider appConfig) async {
    final deviceModel = await _ensureDeviceModel();

    final excludeList =
        (appConfig.config?.autoUpload.excludeDeviceModels ?? const [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

    if (excludeList.contains(deviceModel.trim())) {
      debugPrint('[ImageSync] 当前设备($deviceModel) 在 exclude_device_models 中，跳过');
      return;
    }

    debugPrint('[ImageSync] 当前设备型号: $deviceModel，开始扫描');

    // 1. 扫描所有 assetId（极快）
    final files = await _scanAllAssets();
    debugPrint('[ImageSync] 扫描完成，共 ${files.length} 个 asset');

    // 2. 找出未上传的
    final candidates = <_FileMeta>[];
    for (final f in files) {
      final rec = await localIndex.get(f.assetId);
      if (rec == null || !rec.uploaded) {
        candidates.add(f);
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[ImageSync] 全部已上传，无需同步');
      return;
    }

    debugPrint('[ImageSync] 本轮需上传 ${candidates.length} 个文件');

    // 3. 串行上传
    for (final meta in candidates) {
      await _handleOneFile(meta);
    }

    debugPrint('[ImageSync] 本轮同步完成');
  }

  /// 只扫描 asset.id，不访问文件
  Future<List<_FileMeta>> _scanAllAssets() async {
    final List<_FileMeta> result = [];

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) return result;

    final album = albums.first;
    final total = await album.assetCountAsync;

    debugPrint('[ImageSync] 主相册: ${album.name}, 总数: $total');

    final assets = await album.getAssetListRange(start: 0, end: total);

    // 1. 创建并启动计时器
    final sw = Stopwatch()..start();

    for (final asset in assets) {
      int fileSize = 0;
      if (asset.mimeType!.startsWith("video")) {
        fileSize = await getAssetSize(asset);
      }

      result.add(
        _FileMeta(
          assetId: asset.id,
          mimeType: asset.mimeType,
          fileSize: fileSize,
          duration: asset.duration,
        ),
      );
    }

    // 2. 停止计时
    sw.stop();
    debugPrint('[ImageSync] 扫描完成，耗时: ${sw.elapsedMilliseconds} ms'); // 输出耗时（毫秒）

    return result;
  }

  /// 处理单个文件（精简数据库版本）
  /// - 只计算 md5（用于秒传）
  /// - 秒传命中 → markUploaded(path)
  /// - 上传成功 → markUploaded(path)
  /// 串行处理单个文件
  Future<void> _handleOneFile(_FileMeta meta) async {
    try {
      final asset = await AssetEntity.fromId(meta.assetId);
      if (asset == null) {
        debugPrint('[ImageSync] 找不到文件 assetId=${meta.assetId}');
        return;
      }

      final file = await asset.file;
      if (file == null) {
        debugPrint('[ImageSync] 无法获取文件: ${meta.assetId}');
        return;
      }

      final md5 = await Md5Util.fileMd5(file.path);

      final status = await uploadApi.checkUploaded(etag: md5);
      if (status.uploaded == true) {
        await localIndex.markUploaded(meta.assetId);
        debugPrint('[ImageSync] 秒传命中: ${meta.assetId}');
        return;
      }

      if (isUpload) {
        await uploadApi.uploadToGallery(filePath: file.path, etag: md5);
        await localIndex.markUploaded(meta.assetId);
        debugPrint('[ImageSync] 上传成功: ${meta.assetId}');
      } else {
        debugPrint('[ImageSync] 跳过上传: ${meta.assetId}');
      }
    } catch (e, s) {
      debugPrint('[ImageSync] 上传失败: ${meta.assetId}, error=$e');
      debugPrint('$s');
    }
  }

  Future<int> getAssetSize(AssetEntity asset) async {
    // 获取文件对象
    File? file = await asset.file;
    if (file != null) {
      // 获取文件大小（字节）
      return await file.length();
    }
    return 0; // 文件不存在时返回0
  }
}

class _FileMeta {
  final String assetId;
  final String? mimeType;
  final int? fileSize;
  final int? duration;

  _FileMeta({
    required this.assetId,
    this.mimeType,
    this.fileSize,
    this.duration,
  });
}
