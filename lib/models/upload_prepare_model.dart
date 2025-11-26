import 'sts_token_model.dart';

/// 上传准备接口返回的数据模型，对应后端 data 字段。
///
/// 根据 status 区分几种情况：
/// - "COMPLETED": 秒传完成，主要使用 [fileUrl]
/// - "NEW": 新文件上传，使用 cosKey / uploadId / chunkSize / totalChunks / sts
/// - "PARTIAL" / "UPLOADING": 断点续传或已存在上传，使用 uploadedChunks 等
class UploadPrepareResult {
  /// 状态：COMPLETED / NEW / PARTIAL / UPLOADING
  final String status;

  /// 文件指纹
  final String fingerprint;

  /// 文件最终访问 URL，仅在 status = COMPLETED 时有意义
  final String? fileUrl;

  /// COS 对象 Key，用于后续分片上传
  final String? cosKey;

  /// COS 分片上传的 UploadId
  final String? uploadId;

  /// 单个分片大小（字节）
  final int? chunkSize;

  /// 总分片数
  final int? totalChunks;

  /// 已上传分片编号列表（从 1 开始）
  final List<int> uploadedChunks;

  /// STS 凭证，可选
  final StsTokenModel? sts;

  UploadPrepareResult({
    required this.status,
    required this.fingerprint,
    this.fileUrl,
    this.cosKey,
    this.uploadId,
    this.chunkSize,
    this.totalChunks,
    required this.uploadedChunks,
    this.sts,
  });

  factory UploadPrepareResult.fromJson(Map<String, dynamic> json) {
    return UploadPrepareResult(
      status: json['status'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      cosKey: json['cos_key'] as String?,
      uploadId: json['upload_id'] as String?,
      chunkSize: _parseInt(json['chunk_size']),
      totalChunks: _parseInt(json['total_chunks']),
      uploadedChunks: _parseIntList(json['uploaded_chunks']),
      sts: json['sts'] is Map<String, dynamic>
          ? StsTokenModel.fromJson(json['sts'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      'fingerprint': fingerprint,
      'file_url': fileUrl,
      'cos_key': cosKey,
      'upload_id': uploadId,
      'chunk_size': chunkSize,
      'total_chunks': totalChunks,
      'uploaded_chunks': uploadedChunks,
      'sts': sts?.toJson(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    }
    return const <int>[];
  }

  /// 是否是已完成（秒传）状态
  bool get isCompleted => status == 'COMPLETED';

  /// 是否是新上传
  bool get isNew => status == 'NEW';

  /// 是否是断点续传/已上传部分分片
  bool get isPartial => status == 'PARTIAL';

  /// 是否是正在上传但还没有任何分片（UPLOADING）
  bool get isUploading => status == 'UPLOADING';
}
