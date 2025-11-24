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
        (appConfig.config?.autoUpload.excludeDeviceModels ?? const <String>[])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

    if (excludeList.contains(deviceModel.trim())) {
      debugPrint('[ImageSync] 当前设备($deviceModel) 在 exclude_device_models 中，跳过');
      return;
    }

    debugPrint('[ImageSync] 当前设备型号: $deviceModel，开始扫描');

    // ★ 1. 全量扫描（轻量）
    final files = await _scanAllImages();
    if (files.isEmpty) {
      debugPrint('[ImageSync] 无图片');
      return;
    }

    debugPrint('[ImageSync] 扫描完成，共 ${files.length} 张图片');

    // ★ 2. 找出未上传的文件（不再比较 size/mtime）
    final candidates = <_FileMeta>[];
    for (final f in files) {
      final record = await localIndex.get(f.path);
      if (record == null || !record.uploaded) {
        candidates.add(f);
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[ImageSync] 没有需要上传的文件');
      return;
    }

    debugPrint('[ImageSync] 需要上传的文件数: ${candidates.length}');

    // ★ 3. 串行上传（防卡顿、无并发）
    for (final meta in candidates) {
      await _handleOneFile(meta); // 串行执行
    }

    debugPrint('[ImageSync] 完成全部上传任务');
  }

  /// 扫描系统媒体库中的所有图片，抽象成文件元数据列表
  /// 分页扫描相册，但每页只读取 path + mtime，不读取文件内容，不算 md5。
  Future<List<_FileMeta>> _scanAllImages() async {
    final result = <_FileMeta>[];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return result;

    final mainAlbum = paths.first;
    final total = await mainAlbum.assetCountAsync;

    debugPrint('[ImageSync] 主相册: ${mainAlbum.name}, 总数: $total');

    const pageSize = 100;
    final totalPages = (total / pageSize).ceil();

    for (int page = 0; page < totalPages; page++) {
      final assets = await mainAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;

        result.add(_FileMeta(path: file.path));
      }
    }

    return result;
  }

  /// 处理单个文件（精简数据库版本）
  /// - 只计算 md5（用于秒传）
  /// - 秒传命中 → markUploaded(path)
  /// - 上传成功 → markUploaded(path)
  Future<void> _handleOneFile(_FileMeta meta) async {
    final path = meta.path;

    try {
      final md5 = await Md5Util.fileMd5(path);

      // 秒传
      final status = await uploadApi.checkUploaded(etag: md5);
      if (status.uploaded == true) {
        await localIndex.markUploaded(path);
        debugPrint('[ImageSync] 秒传命中: $path');
        return;
      }

      // 真正上传
      await uploadApi.uploadToGallery(filePath: path, etag: md5);
      await localIndex.markUploaded(path);

      debugPrint('[ImageSync] 上传成功: $path');
    } catch (e, s) {
      debugPrint('[ImageSync] 上传失败: $path, error: $e');
      debugPrint('$s');
    }
  }
}

class _FileMeta {
  final String path;

  _FileMeta({required this.path});
}
