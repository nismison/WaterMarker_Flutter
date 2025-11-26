// lib/models/upload_chunk_complete_model.dart

/// 上传单个分片完成后的回调结果，对应后端 data 字段。
class UploadChunkCompleteResult {
  /// 文件指纹
  final String fingerprint;

  /// 已完成分片数量
  final int uploadedChunks;

  /// 总分片数
  final int totalChunks;

  /// 是否已全部上传，准备进行合并
  final bool readyToComplete;

  UploadChunkCompleteResult({
    required this.fingerprint,
    required this.uploadedChunks,
    required this.totalChunks,
    required this.readyToComplete,
  });

  factory UploadChunkCompleteResult.fromJson(Map<String, dynamic> json) {
    return UploadChunkCompleteResult(
      fingerprint: json['fingerprint'] as String? ?? '',
      uploadedChunks: _parseInt(json['uploaded_chunks']) ?? 0,
      totalChunks: _parseInt(json['total_chunks']) ?? 0,
      readyToComplete: json['ready_to_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fingerprint': fingerprint,
      'uploaded_chunks': uploadedChunks,
      'total_chunks': totalChunks,
      'ready_to_complete': readyToComplete,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 是否已经上传全部分片，可以调用“合并分片”接口
  bool get isReadyToComplete => readyToComplete;
}
