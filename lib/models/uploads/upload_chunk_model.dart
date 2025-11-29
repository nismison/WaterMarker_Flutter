/// 分片上传相关的数据模型
///
/// 注意：
/// - 后端统一返回 { success, error, data }，
///   现有 ApiClient.safeCall 会：
///   1) 处理 DioException；
///   2) 处理 success=false 的情况并抛 AppNetworkException；
///   3) 抽取 data 字段并返回 Map< String, dynamic >。
///
/// 所以这里的 *Result 都只对应后端 JSON 里的 data 部分。
/// /api/upload/prepare 的请求体
class UploadPrepareRequest {
  final String fingerprint;
  final String fileName;
  final int fileSize;
  final int chunkSize;
  final int totalChunks;

  UploadPrepareRequest({
    required this.fingerprint,
    required this.fileName,
    required this.fileSize,
    required this.chunkSize,
    required this.totalChunks,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fingerprint': fingerprint,
      'file_name': fileName,
      'file_size': fileSize,
      'chunk_size': chunkSize,
      'total_chunks': totalChunks,
    };
  }
}

/// /api/upload/prepare 的 data 部分
///
/// 不同 status 下字段不同：
/// - COMPLETED：fingerprint + file_url；
/// - NEW / PARTIAL / UPLOADING：fingerprint + file 基本信息 / 分片信息。
class UploadPrepareResult {
  final String status; // "COMPLETED" | "NEW" | "PARTIAL" | "UPLOADING"
  final String fingerprint;

  final String? fileUrl;

  final String? fileName;
  final int? fileSize;
  final int? chunkSize;
  final int? totalChunks;
  final List<int> uploadedChunks;

  UploadPrepareResult({
    required this.status,
    required this.fingerprint,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.chunkSize,
    this.totalChunks,
    required this.uploadedChunks,
  });

  factory UploadPrepareResult.fromJson(Map<String, dynamic> json) {
    final uploadedRaw = json['uploaded_chunks'];
    final uploaded = (uploadedRaw is List)
        ? uploadedRaw.where((e) => e != null).map((e) => e as int).toList()
        : <int>[];

    return UploadPrepareResult(
      status: json['status'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] is int ? json['file_size'] as int : null,
      chunkSize: json['chunk_size'] is int ? json['chunk_size'] as int : null,
      totalChunks: json['total_chunks'] is int
          ? json['total_chunks'] as int
          : null,
      uploadedChunks: uploaded,
    );
  }
}

/// /api/upload/chunk/complete 的 data 部分
class UploadChunkCompleteResult {
  final String fingerprint;
  final int uploadedChunks;
  final int totalChunks;

  /// true 表示所有分片已经上传完成，后端 worker 可以开始合并
  final bool readyToMerge;

  UploadChunkCompleteResult({
    required this.fingerprint,
    required this.uploadedChunks,
    required this.totalChunks,
    required this.readyToMerge,
  });

  factory UploadChunkCompleteResult.fromJson(Map<String, dynamic> json) {
    return UploadChunkCompleteResult(
      fingerprint: json['fingerprint'] as String? ?? '',
      uploadedChunks: json['uploaded_chunks'] as int? ?? 0,
      totalChunks: json['total_chunks'] as int? ?? 0,
      readyToMerge: json['ready_to_merge'] as bool? ?? false,
    );
  }
}

/// /api/upload/complete 的 data 部分
///
/// 典型场景：
/// - status == "PENDING_MERGE": 分片齐全，等待 worker 合并；
/// - status == "COMPLETED": worker 已经合并完毕，返回 file_url。
class UploadCompleteResult {
  final String status; // "PENDING_MERGE" | "COMPLETED" 等
  final String fingerprint;
  final String? fileUrl;
  final int? uploadedChunks;
  final int? totalChunks;

  UploadCompleteResult({
    required this.status,
    required this.fingerprint,
    this.fileUrl,
    this.uploadedChunks,
    this.totalChunks,
  });

  factory UploadCompleteResult.fromJson(Map<String, dynamic> json) {
    return UploadCompleteResult(
      status: json['status'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      uploadedChunks: json['uploaded_chunks'] as int?,
      totalChunks: json['total_chunks'] as int?,
    );
  }
}
