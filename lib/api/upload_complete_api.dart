// lib/api/upload_complete_api.dart

import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/upload_complete_model.dart';

/// 文件合并完成相关接口。
class UploadCompleteApi extends ApiClient {
  /// 通知后端：所有分片已经上传成功，请执行 COS 合并操作。
  ///
  /// 对应后端：POST /api/upload/complete
  ///
  /// 请求体：
  /// {
  ///   "fingerprint": "..."
  /// }
  ///
  /// 返回的 data 对应 [UploadCompleteResult]。
  Future<UploadCompleteResult> completeUpload({
    required String fingerprint,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/upload/complete',
        data: <String, dynamic>{
          'fingerprint': fingerprint,
        },
      );
    });

    return UploadCompleteResult.fromJson(data);
  }
}
