import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../providers/app_config_provider.dart';
import '../utils/md5_util.dart';
import '../data/local_media_index.dart';
import '../data/local_media_record.dart';
import '../data/sqflite_media_index.dart';
import '../api/upload_api.dart';
import '../utils/device_util.dart';

class ImageSyncService {
  final LocalMediaIndex localIndex;
  final UploadApi uploadApi;
  final bool isTest;
  final bool isUpload;

  String? _deviceModelCache;

  ImageSyncService({
    LocalMediaIndex? localIndex,
    UploadApi? uploadApi,
    bool? isTest,
    bool? isUpload,
  }) : localIndex = localIndex ?? SqfliteMediaIndex(),
       uploadApi = uploadApi ?? UploadApi(),
       isTest = isTest ?? false,
       isUpload = isUpload ?? true;

  Future<String> _ensureDeviceModel() async {
    if (_deviceModelCache != null) return _deviceModelCache!;
    _deviceModelCache = await DeviceUtil.getDeviceModel(); // 这里就是你前面定义的 brand/model 大小写逻辑
    return _deviceModelCache!;
  }

  /// 对外入口：在权限已就绪后调用
  Future<void> syncAllImages(AppConfigProvider appConfig) async {
    // 0. 读取当前设备型号
    final deviceModel = await _ensureDeviceModel();

    // 1. 从配置中读取排除列表
    final excludeList = (appConfig.config?.autoUpload.excludeDeviceModels ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    // 2. 命中排除列表则直接跳过
    if (excludeList.contains(deviceModel.trim())) {
      debugPrint(
          '[ImageSync] 当前设备($deviceModel) 在 exclude_device_models 中，跳过图片扫描与同步');
      return;
    }

    debugPrint('[ImageSync] 当前设备型号: $deviceModel，开始图片扫描与同步');

    // 1. 扫描系统媒体库里的所有图片
    final files = await _scanAllImageFiles();
    if (files.isEmpty) {
      debugPrint('[ImageSync] 没有扫描到任何图片文件');
      return;
    }

    debugPrint('[ImageSync] 扫描到图片文件数: ${files.length}');

    // 2. 结合本地索引，筛出“需要处理”的文件
    final candidates = <_FileMeta>[];

    if (isTest) {
      // 测试模式：不使用本地索引，全部跑一遍接口
      candidates.addAll(files);
    } else {
      // 正常模式：只处理“新文件 / 有变化 / 未上传”的文件
      for (final f in files) {
        final record = await localIndex.getByPath(f.path);
        if (record == null) {
          // 新文件
          candidates.add(f);
          continue;
        }

        final changed = record.size != f.size || record.mtime != f.mtime;

        if (changed || !record.uploaded) {
          candidates.add(f);
        } else {
          // 已确认上传且未变化，跳过
        }
      }
    }

    if (candidates.isEmpty) {
      debugPrint(
        isTest
            ? '[ImageSync][TEST] 没有候选文件（这一般只会出现在图库本身为空的情况）'
            : '[ImageSync] 没有需要同步的文件，全部已上传且未变化',
      );
      return;
    }

    debugPrint('[ImageSync] 需要处理的文件数: ${candidates.length} (isTest=$isTest)');

    // 3. 控制并发，避免一次性把 CPU / IO 打爆
    final cpu = Platform.numberOfProcessors;
    final maxConcurrent = cpu <= 2 ? 2 : (cpu - 1).clamp(2, 6);
    debugPrint('[ImageSync] 设备 CPU: $cpu, 并发数: $maxConcurrent');

    await _processWithConcurrency<_FileMeta>(
      candidates,
      maxConcurrent,
      _handleOneFile,
    );

    debugPrint('[ImageSync] 同步任务结束 (isTest=$isTest)');
  }

  /// 扫描系统媒体库中的所有图片，抽象成文件元数据列表
  Future<List<_FileMeta>> _scanAllImageFiles() async {
    final result = <_FileMeta>[];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return result;

    final mainAlbum = paths.first;
    final total = await mainAlbum.assetCountAsync;
    const pageSize = 200;

    debugPrint('[ImageSync] 主相册: ${mainAlbum.name}, 总数: $total');

    for (int page = 0; page * pageSize < total; page++) {
      final assets = await mainAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;

        final stat = await file.stat();
        result.add(
          _FileMeta(
            path: file.path,
            size: stat.size,
            mtime: stat.modified.millisecondsSinceEpoch,
          ),
        );
      }
    }

    return result;
  }

  /// 处理单个文件
  Future<void> _handleOneFile(_FileMeta meta) async {
    final path = meta.path;

    try {
      // --------------------
      // 测试模式：只跑接口，不动本地 DB
      // --------------------
      if (isTest) {
        final md5 = await Md5Util.fileMd5(path);
        debugPrint('[ImageSync][TEST] 开始检查: $path, etag(md5)=$md5');

        final status = await uploadApi.checkUploaded(etag: md5);
        final alreadyUploaded =
            status.uploaded == true; // 根据你的 UploadStatus 字段改

        if (alreadyUploaded) {
          debugPrint('[ImageSync][TEST] 已存在(秒传命中): $path');
        } else {
          debugPrint(
            '[ImageSync][TEST] 不存在，调用 uploadToGallery: $path, etag=$md5',
          );
          await uploadApi.uploadToGallery(filePath: path, etag: md5);
          debugPrint('[ImageSync][TEST] uploadToGallery 调用完成: $path');
        }

        return; // 测试模式到此为止，不写数据库
      }

      // --------------------
      // 正常模式：带本地索引的完整流程
      // --------------------
      final now = DateTime.now().millisecondsSinceEpoch;

      final existing = await localIndex.getByPath(path);

      String md5;
      LocalMediaRecord recordForSave;

      if (existing != null && existing.md5 != null) {
        md5 = existing.md5!;
        recordForSave = existing.copyWith(
          size: meta.size,
          mtime: meta.mtime,
          lastCheckTs: now,
        );
      } else {
        md5 = await Md5Util.fileMd5(path);

        if (existing != null) {
          recordForSave = existing.copyWith(
            md5: md5,
            size: meta.size,
            mtime: meta.mtime,
            lastCheckTs: now,
          );
        } else {
          recordForSave = LocalMediaRecord(
            path: path,
            size: meta.size,
            mtime: meta.mtime,
            md5: md5,
            uploaded: false,
            firstSeenTs: now,
            lastCheckTs: now,
            lastUploadTs: null,
            errorCount: 0,
            lastError: null,
          );
        }
      }

      // 落库（缓存 md5 / size / mtime）
      await localIndex.upsert(recordForSave);

      final status = await uploadApi.checkUploaded(etag: md5);
      final alreadyUploaded = status.uploaded == true;

      if (alreadyUploaded) {
        await localIndex.markUploaded(
          path: path,
          md5: md5,
          size: meta.size,
          mtime: meta.mtime,
        );
        debugPrint('[ImageSync] 秒传命中(已存在): $path');
        return;
      }

      if (isUpload) {
        await uploadApi.uploadToGallery(filePath: path, etag: md5);

        await localIndex.markUploaded(
          path: path,
          md5: md5,
          size: meta.size,
          mtime: meta.mtime,
        );
        debugPrint('[ImageSync] 已上传: $path');
      } else {
        debugPrint('[ImageSync] 手动跳过上传: $path');
      }
    } catch (e, s) {
      debugPrint('[ImageSync] 处理文件失败: $path, error: $e');
      debugPrint('$s');

      // 正常模式下可以记录错误，测试模式下直接忽略 DB
      // if (!isTest && localIndex is SqfliteMediaIndex) {
      //   await (localIndex as SqfliteMediaIndex)
      //       .markError(path: path, message: '$e');
      // }
    }
  }

  /// 简单的限流并发处理器
  Future<void> _processWithConcurrency<T>(
    List<T> items,
    int concurrency,
    Future<void> Function(T item) worker,
  ) async {
    if (items.isEmpty) return;
    if (concurrency <= 1 || items.length <= 1) {
      for (final item in items) {
        await worker(item);
      }
      return;
    }

    final total = items.length;
    final per = (total / concurrency).ceil();
    final futures = <Future<void>>[];

    for (int i = 0; i < concurrency; i++) {
      final start = i * per;
      if (start >= total) break;
      final end = (start + per).clamp(0, total);
      final slice = items.sublist(start, end);
      futures.add(_processSlice(slice, worker));
    }

    await Future.wait(futures);
  }

  Future<void> _processSlice<T>(
    List<T> slice,
    Future<void> Function(T item) worker,
  ) async {
    for (final item in slice) {
      await worker(item);
    }
  }
}

class _FileMeta {
  final String path;
  final int size;
  final int mtime;

  _FileMeta({required this.path, required this.size, required this.mtime});
}
