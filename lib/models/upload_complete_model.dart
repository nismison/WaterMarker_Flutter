// lib/models/upload_complete_model.dart

/// 整个文件合并完成后的结果，对应后端 data 字段。
class UploadCompleteResult {
  /// 状态，目前固定为 "COMPLETED"
  final String status;

  /// 文件最终访问 URL
  final String fileUrl;

  /// COS 对象 Key
  final String cosKey;

  /// 文件指纹
  final String fingerprint;

  UploadCompleteResult({
    required this.status,
    required this.fileUrl,
    required this.cosKey,
    required this.fingerprint,
  });

  factory UploadCompleteResult.fromJson(Map<String, dynamic> json) {
    return UploadCompleteResult(
      status: json['status'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      cosKey: json['cos_key'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      'file_url': fileUrl,
      'cos_key': cosKey,
      'fingerprint': fingerprint,
    };
  }

  bool get isCompleted => status == 'COMPLETED';
}
