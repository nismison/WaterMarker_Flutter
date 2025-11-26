import 'package:watermarker_v2/api/api_client.dart';
import 'package:watermarker_v2/models/upload_chunk_model.dart';

/// 分片上传相关接口统一封装：
/// - /api/sts/token
/// - /api/upload/prepare
/// - /api/upload/chunk/complete
/// - /api/upload/complete
class UploadChunkApi extends ApiClient {
  /// 获取当前有效的 COS STS 信息。
  ///
  /// 对应后端：GET /api/sts/token
  ///
  /// 预期后端返回格式（示例）：
  /// {
  ///   "success": true,
  ///   "error": "",
  ///   "data": {
  ///     "tmpSecretId": "...",
  ///     "tmpSecretKey": "...",
  ///     "sessionToken": "...",
  ///     "expiredTime": "1764135002",
  ///     "bucketName": "xxx",
  ///     "region": "ap-guangzhou",
  ///     "uploadPath": "prod/.../",
  ///     "uploadUrl": "https://xxx.cos.ap-guangzhou.myqcloud.com",
  ///     "allowedActions": ["cos:PutObject", "..."],
  ///     "resourcePath": "qcs::cos:...",
  ///     "permissions": {
  ///       "canUpload": true,
  ///       "uploadDirectory": "h5-app",
  ///       "businessType": "video"
  ///     }
  ///   }
  /// }
  Future<StsTokenModel> fetchStsToken() async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.get('/api/sts/token');
    });

    return StsTokenModel.fromJson(data);
  }

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
  /// 返回的 data 对应 [UploadPrepareResult]：
  /// - 已完成（秒传）：
  ///   {
  ///     "status": "COMPLETED",
  ///     "fingerprint": "...",
  ///     "file_url": "..."
  ///   }
  /// - 新文件：
  ///   {
  ///     "status": "NEW",
  ///     "fingerprint": "...",
  ///     "cos_key": "...",
  ///     "upload_id": "...",
  ///     "chunk_size": 5242880,
  ///     "total_chunks": 24,
  ///     "uploaded_chunks": [],
  ///     "sts": {...}
  ///   }
  /// - 断点续传 / 正在上传：
  ///   {
  ///     "status": "PARTIAL" | "UPLOADING",
  ///     "fingerprint": "...",
  ///     "cos_key": "...",
  ///     "upload_id": "...",
  ///     "chunk_size": 5242880,
  ///     "total_chunks": 24,
  ///     "uploaded_chunks": [1, 2, ...],
  ///     "sts": {...}
  ///   }
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
  /// 返回的 data 对应 [UploadChunkCompleteResult]：
  /// {
  ///   "fingerprint": "...",
  ///   "uploaded_chunks": 10,
  ///   "total_chunks": 24,
  ///   "ready_to_complete": true/false
  /// }
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

  /// 通知后端：所有分片已经上传成功，请执行 COS 合并操作。
  ///
  /// 对应后端：POST /api/upload/complete
  ///
  /// 请求体：
  /// {
  ///   "fingerprint": "..."
  /// }
  ///
  /// 成功时 data 对应 [UploadCompleteResult]：
  /// {
  ///   "status": "COMPLETED",
  ///   "file_url": "...",
  ///   "cos_key": "...",
  ///   "fingerprint": "..."
  /// }
  ///
  /// 分片数量不完整等业务错误，会通过 AppNetworkException 抛出，
  /// 具体错误信息在 exception.data 中。
  Future<UploadCompleteResult> completeUpload({
    required String fingerprint,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/upload/complete',
        data: <String, dynamic>{'fingerprint': fingerprint},
      );
    });

    return UploadCompleteResult.fromJson(data);
  }
}
