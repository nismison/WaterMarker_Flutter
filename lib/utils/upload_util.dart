// lib/utils/upload_util.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:watermarker_v2/api/upload_chunk_api.dart';

import 'package:watermarker_v2/models/upload_chunk_model.dart';
import 'file_util.dart';

/// 秒传检测结果：带上 fingerprint / md5，方便后续继续用
class InstantUploadResult {
  final bool uploaded; // 是否已在服务器存在（秒传命中）
  final String fingerprint;
  final String? md5; // 只有 fingerprint+md5 检查时才会有

  InstantUploadResult({
    required this.uploaded,
    required this.fingerprint,
    this.md5,
  });
}

/// 仅 fingerprint 检查秒传的结果
class FingerprintCheckResult {
  final bool uploaded;
  final String fingerprint;

  FingerprintCheckResult({required this.uploaded, required this.fingerprint});
}

class UploadUtil {
  /// 1. 基于 fingerprint + md5 检测秒传是否命中
  ///
  /// 逻辑：
  ///   1) file.fingerprint() -> uploadApi.checkUploaded(fingerprint)
  ///   2) 未命中 -> file.md5() -> uploadApi.checkUploaded(etag + fingerprint)
  ///   3) 命中时可选 markUploaded + 打日志
  static Future<InstantUploadResult> checkFingerprintAndMd5InstantUpload({
    required File file,
    required dynamic uploadApi, // 需要有 checkUploaded({fingerprint, etag}) 方法
    required dynamic localIndex, // 需要有 markUploaded(assetId) 方法
    required String assetId,
    bool markUploadedOnHit = true,
  }) async {
    // 1) fingerprint
    final fp = await file.fingerprint();
    final fingerUploadedStatus = await uploadApi.checkUploaded(fingerprint: fp);
    if (fingerUploadedStatus.uploaded == true) {
      if (markUploadedOnHit) {
        await localIndex.markUploaded(assetId);
      }
      debugPrint('[ImageSync] fingerprint 秒传命中: $assetId');
      return InstantUploadResult(uploaded: true, fingerprint: fp, md5: null);
    }

    // 2) md5
    final md5 = await file.md5();
    final md5UploadedStatus = await uploadApi.checkUploaded(
      etag: md5,
      fingerprint: fp,
    );
    if (md5UploadedStatus.uploaded == true) {
      if (markUploadedOnHit) {
        await localIndex.markUploaded(assetId);
      }
      debugPrint('[ImageSync] md5 秒传命中: $assetId');
      return InstantUploadResult(uploaded: true, fingerprint: fp, md5: md5);
    }

    // 未命中，返回 fingerprint + md5，方便后续上传使用
    return InstantUploadResult(uploaded: false, fingerprint: fp, md5: md5);
  }

  /// 2. 仅基于 fingerprint 检测秒传是否命中
  static Future<FingerprintCheckResult> checkFingerprintInstantUpload({
    required File file,
    required dynamic uploadApi,
    required dynamic localIndex,
    required String assetId,
    bool markUploadedOnHit = true,
  }) async {
    final fp = await file.fingerprint();
    final fingerUploadedStatus = await uploadApi.checkUploaded(fingerprint: fp);
    if (fingerUploadedStatus.uploaded == true) {
      if (markUploadedOnHit) {
        await localIndex.markUploaded(assetId);
      }
      debugPrint('[ImageSync] fingerprint 秒传命中(大视频): $assetId');
      return FingerprintCheckResult(uploaded: true, fingerprint: fp);
    }

    return FingerprintCheckResult(uploaded: false, fingerprint: fp);
  }

  /// 3. 大视频分片上传完整流程
  ///
  /// 步骤：
  ///   - 调 /api/upload/prepare 拿到已上传分片列表（断点续传）
  ///   - 按 chunkSize 切文件 -> 逐片调用 /api/upload/chunk/complete
  ///   - 最后调用 /api/upload/complete 进入合并流程
  ///   - 成功后 markUploaded
  static Future<void> uploadVideoInChunks({
    required File file,
    required String fingerprint,
    required int fileSize,
    required UploadChunkApi uploadChunkApi,
    required dynamic localIndex,
    required String assetId,
    int chunkSize = 5 * 1024 * 1024,
  }) async {
    final String fileName = file.path.split(Platform.pathSeparator).last;

    final int totalChunks = (fileSize + chunkSize - 1) ~/ chunkSize;

    // 1. prepare
    final prepareResult = await uploadChunkApi.uploadPrepare(
      UploadPrepareRequest(
        fingerprint: fingerprint,
        fileName: fileName,
        fileSize: fileSize,
        chunkSize: chunkSize,
        totalChunks: totalChunks,
      ),
    );

    if (prepareResult.status == 'COMPLETED') {
      // 后端已经有完整文件，等同于秒传
      await localIndex.markUploaded(assetId);
      debugPrint('[ImageSync] 分片上传秒传命中(大视频): $assetId');
      return;
    }

    final alreadyUploaded = prepareResult.uploadedChunks.toSet();

    // 2. 分片上传
    final raf = await file.open();
    try {
      for (int partNumber = 1; partNumber <= totalChunks; partNumber++) {
        if (alreadyUploaded.contains(partNumber)) {
          // 断点续传已完成的分片，跳过
          continue;
        }

        final int start = (partNumber - 1) * chunkSize;
        final int end = (start + chunkSize > fileSize)
            ? fileSize
            : start + chunkSize;
        final int length = end - start;

        await raf.setPosition(start);
        final bytes = await raf.read(length);

        final tmpFile = File(
          '${Directory.systemTemp.path}/upload_chunk_${fingerprint}_$partNumber.part',
        );
        await tmpFile.writeAsBytes(bytes, flush: false);

        await uploadChunkApi.uploadChunkComplete(
          fingerprint: fingerprint,
          partNumber: partNumber,
          file: tmpFile,
        );

        await tmpFile.delete();

        debugPrint(
          '[ImageSync] 分片上传完成: $assetId, part=$partNumber/$totalChunks',
        );
      }
    } finally {
      await raf.close();
    }

    // 3. 通知后端：所有分片已上传，进入合并阶段
    final completeResult = await uploadChunkApi.uploadComplete(
      fingerprint: fingerprint,
    );

    if (completeResult.status == 'COMPLETED' ||
        completeResult.status == 'PENDING_MERGE') {
      await localIndex.markUploaded(assetId);
      debugPrint(
        '[ImageSync] 大视频分片上传成功: $assetId, status=${completeResult.status}',
      );
    } else {
      debugPrint(
        '[ImageSync] 大视频分片上传完成但状态异常: $assetId, status=${completeResult.status}',
      );
    }
  }
}
