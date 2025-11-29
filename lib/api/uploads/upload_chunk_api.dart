import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermarker_v2/api/client/api_client.dart';
import 'package:watermarker_v2/models/uploads/upload_chunk_model.dart';

/// 分片上传相关接口封装。
///
/// 不重复造 HttpClient / safeCall：
/// 统一继承现有 ApiClient，复用里面的：
/// - Dio 实例（含公共拦截器 / 超时配置等）
/// - safeCall 统一处理异常 + success=false + 提取 data
class UploadChunkApi extends ApiClient {
  // =========================
  // 1. /api/upload/prepare
  // =========================

  Future<UploadPrepareResult> uploadPrepare(
    UploadPrepareRequest request,
  ) async {
    final Map<String, dynamic> data = await safeCall(
      () => dio.post('/api/upload/prepare', data: request.toJson()),
    );

    return UploadPrepareResult.fromJson(data);
  }

  // =========================
  // 2. /api/upload/chunk/complete
  // =========================

  /// 上传单个分片。
  ///
  /// 约定：后端接口为 multipart/form-data：
  ///   - fingerprint: String
  ///   - part_number: String/int
  ///   - file: 分片二进制
  ///
  /// 这里选择直接用 File，而不是把 bytes 拉到内存里，避免大文件压爆内存。
  Future<UploadChunkCompleteResult> uploadChunkComplete({
    required String fingerprint,
    required int partNumber,
    required File file,
    String? fileNameOverride,
  }) async {
    final fileName =
        fileNameOverride ?? file.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'fingerprint': fingerprint,
      'part_number': partNumber.toString(),
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final Map<String, dynamic> data = await safeCall(
      () => dio.post('/api/upload/chunk/complete', data: formData),
    );

    return UploadChunkCompleteResult.fromJson(data);
  }

  // =========================
  // 3. /api/upload/complete
  // =========================

  /// 分片全部上传完后调用，告知后端进入“待合并”状态。
  ///
  /// 本地实现里：
  ///   - 如果 file.status == COMPLETED 且有 url，会直接返回 status=COMPLETED + file_url；
  ///   - 否则分片齐全时返回 status=PENDING_MERGE，后端 worker 会在后台合并；
  ///   - 分片不齐全时后端会返回 success=false，safeCall 会抛异常。
  Future<UploadCompleteResult> uploadComplete({
    required String fingerprint,
  }) async {
    final Map<String, dynamic> data = await safeCall(
      () => dio.post(
        '/api/upload/complete',
        data: <String, dynamic>{'fingerprint': fingerprint},
      ),
    );

    return UploadCompleteResult.fromJson(data);
  }
}
