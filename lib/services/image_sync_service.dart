import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:watermarker_v2/providers/app_config_provider.dart';
import 'package:watermarker_v2/utils/file_util.dart';
import 'package:watermarker_v2/data/local_media_index.dart';
import 'package:watermarker_v2/data/sqflite_media_index.dart';
import 'package:watermarker_v2/api/upload_api.dart';
import 'package:watermarker_v2/utils/device_util.dart';

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

    // 1. 创建并启动计时器
    final sw = Stopwatch()..start();

    debugPrint('[ImageSync] 当前设备型号: $deviceModel，开始扫描');

    // 1. 扫描所有 assetId（极快）
    final assets = await _scanAllAssets();
    debugPrint('[ImageSync] 扫描完成，共 ${assets.length} 个资源');

    // 2. 查询数据库数据(没有记录或未上传)
    final candidates = <AssetEntity>[];
    for (final asset in assets) {
      final rec = await localIndex.get(asset.id);
      if (rec == null || !rec.uploaded) {
        // TODO 计算视频文件 md5
        // int fileSize = 0;
        // if (asset.mimeType!.startsWith("video")) {
        //   fileSize = await getAssetSize(asset);
        // }

        candidates.add(asset);
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[ImageSync] 全部已上传，无需同步');
      return;
    }

    sw.stop();
    debugPrint(
      '[ImageSync] 本轮需上传 ${candidates.length} 个文件，耗时: ${sw.elapsedMilliseconds} ms',
    );

    // 3. 串行上传
    for (final meta in candidates) {
      await _handleOneFile(meta);
    }

    debugPrint('[ImageSync] 本轮同步完成');
  }

  /// 只扫描 asset.id，不访问文件
  Future<List<AssetEntity>> _scanAllAssets() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];

    final album = albums.first;
    final total = await album.assetCountAsync;

    final assets = await album.getAssetListRange(start: 0, end: total);
    final filteredAssets = assets
        .where(
          (asset) =>
              asset.relativePath != null &&
              !asset.relativePath!.contains('lebang'),
        )
        .toList();

    return filteredAssets;
  }

  /// 处理单个文件（精简数据库版本）
  /// - 只计算 md5（用于秒传）
  /// - 秒传命中 → markUploaded(asset.id)
  /// - 上传成功 → markUploaded(asset.id)
  /// 串行处理单个文件
  Future<void> _handleOneFile(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) {
        debugPrint('[ImageSync] 无法获取文件: ${asset.id}');
        return;
      }

      // 优先检测 fingerprint
      final fp = await file.fingerprint();
      final fingerUploadedStatus = await uploadApi.checkUploaded(
        fingerprint: fp,
      );
      if (fingerUploadedStatus.uploaded == true) {
        await localIndex.markUploaded(asset.id);
        debugPrint('[ImageSync] fingerprint 秒传命中: ${asset.id}');
        return;
      }

      // fingerprint 秒传未命中，尝试 md5 秒传
      final md5 = await file.md5();
      final md5UploadedStatus = await uploadApi.checkUploaded(etag: md5);
      if (md5UploadedStatus.uploaded == true) {
        await localIndex.markUploaded(asset.id);
        debugPrint('[ImageSync] md5 秒传命中: ${asset.id}');
        return;
      }

      // 秒传未命中，开始上传
      if (isUpload) {
        await uploadApi.uploadToGallery(filePath: file.path, etag: md5);
        await localIndex.markUploaded(asset.id);
        debugPrint('[ImageSync] 上传成功: ${asset.id}');
      } else {
        debugPrint('[ImageSync] 跳过上传: ${asset.id}');
      }
    } catch (e, s) {
      debugPrint('[ImageSync] 上传失败: ${asset.id}, error=$e');
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
