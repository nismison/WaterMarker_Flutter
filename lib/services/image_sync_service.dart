import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermarker_v2/api/filesync/upload_api.dart';
import 'package:watermarker_v2/api/filesync/upload_chunk_api.dart';
import 'package:watermarker_v2/api/notify_api.dart';
import 'package:watermarker_v2/data/local_media_index.dart';
import 'package:watermarker_v2/data/sqflite_media_index.dart';
import 'package:watermarker_v2/models/app_config_model.dart';
import 'package:watermarker_v2/utils/device_util.dart';
import 'package:watermarker_v2/utils/storage_util.dart';
import 'package:watermarker_v2/utils/upload_util.dart';

class ImageSyncService {
  final LocalMediaIndex localIndex;
  final UploadApi uploadApi;
  final UploadChunkApi uploadChunkApi;
  final bool isUpload;

  String? _deviceModelCache;

  ImageSyncService({
    LocalMediaIndex? localIndex,
    UploadApi? uploadApi,
    UploadChunkApi? uploadChunkApi,
    bool? isTest,
    bool? isUpload,
  }) : localIndex = localIndex ?? SqfliteMediaIndex(),
       uploadApi = uploadApi ?? UploadApi(),
       uploadChunkApi = uploadChunkApi ?? UploadChunkApi(),
       isUpload = isUpload ?? true;

  Future<String> _ensureDeviceModel() async {
    if (_deviceModelCache != null) return _deviceModelCache!;
    _deviceModelCache =
        await DeviceUtil.getDeviceModel(); // 这里就是你前面定义的 brand/model 大小写逻辑
    return _deviceModelCache!;
  }

  /// 对外入口：在权限已就绪后调用
  Future<void> syncAllImages(AppConfigModel? appConfig, {bool notify = false}) async {
    final deviceModel = await _ensureDeviceModel();

    final hasAll = await StorageUtil.hasAllFilesAccess();
    if (!hasAll) {
      debugPrint("[ImageSync] 未授予文件访问权限，跳过自动同步");
      if (notify) NotifyApi().sendNotify("[ImageSync] 未授予文件访问权限，跳过自动同步");
      return;
    }

    final excludeList =
        (appConfig?.autoUpload.excludeDeviceModels ?? [deviceModel.trim()])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

    if (excludeList.contains(deviceModel.trim())) {
      debugPrint('[ImageSync] 当前设备($deviceModel) 在 exclude_device_models 中，跳过');
      if (notify) NotifyApi().sendNotify('[ImageSync] 当前设备($deviceModel) 在 exclude_device_models 中，跳过');
      return;
    }

    // 1. 创建并启动计时器
    final sw = Stopwatch()..start();

    debugPrint('[ImageSync] 当前设备型号: $deviceModel，开始扫描');
    if (notify) NotifyApi().sendNotify('[ImageSync] 当前设备型号: $deviceModel，开始扫描');

    // 1. 扫描所有 assetId（极快）
    PhotoManager.setIgnorePermissionCheck(true);
    final assets = await _scanAllAssets();
    debugPrint('[ImageSync] 扫描完成，共 ${assets.length} 个资源');
    if (notify) NotifyApi().sendNotify('[ImageSync] 扫描完成，共 ${assets.length} 个资源');

    // 2. 查询数据库数据(没有记录或未上传)
    final candidates = <AssetEntity>[];
    for (final asset in assets) {
      final rec = await localIndex.get(asset.id);
      if (rec == null || !rec.uploaded) {
        candidates.add(asset);
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[ImageSync] 全部已上传，无需同步');
      if (notify) NotifyApi().sendNotify('[ImageSync] 全部已上传，无需同步');
      return;
    }

    sw.stop();
    debugPrint(
      '[ImageSync] 本轮需上传 ${candidates.length} 个文件，耗时: ${sw.elapsedMilliseconds} ms',
    );
    if (notify) NotifyApi().sendNotify('[ImageSync] 本轮需上传 ${candidates.length} 个文件，耗时: ${sw.elapsedMilliseconds} ms');

    // 3. 串行上传
    for (final meta in candidates) {
      await _handleOneFile(meta);
    }

    debugPrint('[ImageSync] 本轮同步完成');
    if (notify) NotifyApi().sendNotify('[ImageSync] 本轮同步完成');
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

      // 判断是否是「大视频」
      final bool isBigVideo =
          asset.type == AssetType.video &&
          await getAssetSize(asset) > 10 * 1024 * 1024;

      // =========================
      // 图片 或 小于等于 10MB 的视频
      // =========================
      if (!isBigVideo) {
        // 1. 基于 fingerprint + md5 检测秒传
        final instant = await UploadUtil.checkFingerprintAndMd5InstantUpload(
          file: file,
          uploadApi: uploadApi,
          localIndex: localIndex,
          assetId: asset.id,
        );

        if (instant.uploaded) {
          // 秒传命中，已经在 util 里 markUploaded+日志，直接返回
          return;
        }

        if (!isUpload) {
          debugPrint('[ImageSync] 跳过上传: ${asset.id}');
          return;
        }

        // 2. 秒传未命中，使用原有的 uploadToGallery 上传整文件
        await uploadApi.uploadToGallery(
          filePath: file.path,
          etag: instant.md5 ?? '', // util 已经算过 md5
          fingerprint: instant.fingerprint,
        );
        await localIndex.markUploaded(asset.id);
        debugPrint('[ImageSync] 上传成功: ${asset.id}');
        return;
      }

      // =========================
      // 大于 10MB 的视频：只做 fingerprint 秒传 + 分片上传
      // =========================

      // 1. 仅 fingerprint 秒传检测
      final fpResult = await UploadUtil.checkFingerprintInstantUpload(
        file: file,
        uploadApi: uploadApi,
        localIndex: localIndex,
        assetId: asset.id,
      );

      if (fpResult.uploaded) {
        // 秒传命中，已经在 util 里 markUploaded+日志，直接返回
        return;
      }

      if (!isUpload) {
        debugPrint('[ImageSync] 跳过上传(大视频): ${asset.id}');
        return;
      }

      // 2. 分片上传
      final int fileSize = await getAssetSize(asset);

      await UploadUtil.uploadVideoInChunks(
        file: file,
        fingerprint: fpResult.fingerprint,
        fileSize: fileSize,
        uploadChunkApi: uploadChunkApi,
        localIndex: localIndex,
        assetId: asset.id,
      );
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
