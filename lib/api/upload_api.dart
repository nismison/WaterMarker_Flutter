import 'package:dio/dio.dart';

import 'package:watermarker_v2/models/upload_status_model.dart';
import 'api_client.dart';

/// 上传相关 API
class UploadApi extends ApiClient {
  /// 上传到相册目录，加入后台队列异步上传 Immich
  ///
  /// 对应后端：
  ///   POST /api/upload_to_gallery
  ///   form-data:
  ///     - file: 文件
  ///     - etag: 字符串
  ///
  /// 成功时后端返回：
  ///   {"success": true, "message": "..."}  （建议后端后续统一加 data 字段）
  ///
  /// 失败时会抛 AppNetworkException。

  // 调用示例
  // import 'package:your_app/api/upload_api.dart';
  //
  // final _uploadApi = UploadApi();
  //
  // Future<void> handleUploadToGallery(String path, String etag) async {
  //   try {
  //     await _uploadApi.uploadToGallery(filePath: path, etag: etag);
  //     // 成功以后你可以本地直接弹一个固定提示
  //     // 比如：Snackbar / Toast / Dialog
  //     debugPrint('文件已加入上传队列，后端稍后自动上传 Immich');
  //   } catch (e) {
  //     // 这里 e 通常是 AppNetworkException，可以根据需要特殊处理
  //     debugPrint('上传到相册失败: $e');
  //   }
  // }
  Future<void> uploadToGallery({
    required String filePath,
    required String etag,
    required String fingerprint,
  }) async {
    // 先构造表单
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'etag': etag,
      'fingerprint': fingerprint,
    });

    // 这里我们只关心成功/失败，不关心返回的 data
    await safeCall(() {
      return dio.post('/api/upload_to_gallery', data: formData);
    });
  }

  /// 检查文件是否已上传
  ///
  /// - `etag` 和 `fingerprint` 至少需要一个不能同时为空
  /// - 只有一个参数时就只按那一个查询
  /// - 两个都有时，后端会优先用 fingerprint，再按你定义的规则回填 fingerprint
  Future<UploadStatus> checkUploaded({
    String? etag,
    String? fingerprint,
  }) async {
    // 本地兜底校验，避免发无效请求
    if ((etag == null || etag.isEmpty) &&
        (fingerprint == null || fingerprint.isEmpty)) {
      throw ArgumentError('etag 和 fingerprint 不能同时为空');
    }

    final queryParams = <String, dynamic>{};
    if (etag != null && etag.isNotEmpty) {
      queryParams['etag'] = etag;
    }
    if (fingerprint != null && fingerprint.isNotEmpty) {
      queryParams['fingerprint'] = fingerprint;
    }

    final Map<String, dynamic> data = await safeCall(() {
      return dio.get('/api/check_uploaded', queryParameters: queryParams);
    });

    return UploadStatus.fromJson(data);
  }
}
