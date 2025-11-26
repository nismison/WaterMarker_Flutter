import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/upload_prepare_model.dart';

/// 上传准备相关接口封装。
class UploadPrepareApi extends ApiClient {
  /// 调用上传准备接口。
  ///
  /// 对应后端：POST /api/upload/prepare
  ///
  /// 请求体：
  /// {
  ///   "fingerprint": "...",
  ///   "file_name": "xxx.mp4",
  ///   "file_size": 123456,
  ///   "chunk_size": 5242880,
  ///   "total_chunks": 24
  /// }
  ///
  /// 返回的 data 对应 [UploadPrepareResult]。
  Future<UploadPrepareResult> prepareUpload({
    required String fingerprint,
    required String fileName,
    required int fileSize,
    required int chunkSize,
    required int totalChunks,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/upload/prepare',
        data: <String, dynamic>{
          'fingerprint': fingerprint,
          'file_name': fileName,
          'file_size': fileSize,
          'chunk_size': chunkSize,
          'total_chunks': totalChunks,
        },
      );
    });

    return UploadPrepareResult.fromJson(data);
  }
}
