// lib/api/upload_chunk_api.dart

import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/upload_chunk_complete_model.dart';

/// 分片上传相关接口。
class UploadChunkApi extends ApiClient {
  /// 上报单个分片在 COS 上传成功的结果。
  ///
  /// 对应后端：POST /api/upload/chunk/complete
  ///
  /// 请求体：
  /// {
  ///   "fingerprint": "...",
  ///   "part_number": 1,
  ///   "etag": "xxxxx"
  /// }
  ///
  /// 返回的 data 对应 [UploadChunkCompleteResult]。
  Future<UploadChunkCompleteResult> completeChunk({
    required String fingerprint,
    required int partNumber,
    required String etag,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/upload/chunk/complete',
        data: <String, dynamic>{
          'fingerprint': fingerprint,
          'part_number': partNumber,
          'etag': etag,
        },
      );
    });

    return UploadChunkCompleteResult.fromJson(data);
  }
}
