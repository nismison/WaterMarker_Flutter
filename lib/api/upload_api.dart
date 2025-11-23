import 'package:dio/dio.dart';

import '../models/upload_status_model.dart';
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
  }) async {
    // 先构造表单
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'etag': etag,
    });

    // 这里我们只关心成功/失败，不关心返回的 data
    await safeCall(() {
      return dio.post('/api/upload_to_gallery', data: formData);
    });
  }

  /// 检查 etag 是否已经上传过
  ///
  /// 对应后端：
  ///   GET /api/check_uploaded?etag=xxx
  ///
  /// 返回格式：
  ///   {
  ///     "success": true,
  ///     "error": "",
  ///     "data": { "uploaded": true/false }
  ///   }
  Future<UploadStatus> checkUploaded({required String etag}) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.get('/api/check_uploaded', queryParameters: {'etag': etag});
    });

    return UploadStatus.fromJson(data);
  }
}
