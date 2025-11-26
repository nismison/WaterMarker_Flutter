/// STS 权限信息（data.permissions）
class StsPermissions {
  /// 是否允许上传
  final bool canUpload;

  /// 上传目录（例如 "h5-app"）
  final String uploadDirectory;

  /// 业务类型（例如 "video"）
  final String businessType;

  StsPermissions({
    required this.canUpload,
    required this.uploadDirectory,
    required this.businessType,
  });

  factory StsPermissions.fromJson(Map<String, dynamic> json) {
    return StsPermissions(
      canUpload: json['canUpload'] as bool? ?? false,
      uploadDirectory: json['uploadDirectory'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canUpload': canUpload,
      'uploadDirectory': uploadDirectory,
      'businessType': businessType,
    };
  }
}

/// COS STS 临时凭证数据模型，对应 /api/sts/token 的 data 字段。
///
/// 示例：
/// {
///   "tmpSecretId": "...",
///   "tmpSecretKey": "...",
///   "sessionToken": "...",
///   "expiredTime": "1764135002",
///   "bucketName": "xxx",
///   "region": "ap-guangzhou",
///   "uploadPath": "prod/.../",
///   "uploadUrl": "https://xxx.cos.ap-guangzhou.myqcloud.com",
///   "allowedActions": ["cos:PutObject", "..."],
///   "resourcePath": "qcs::cos:...",
///   "permissions": {
///     "canUpload": true,
///     "uploadDirectory": "h5-app",
///     "businessType": "video"
///   }
/// }
class StsTokenModel {
  /// 临时密钥 ID
  final String tmpSecretId;

  /// 临时密钥 Key
  final String tmpSecretKey;

  /// 会话 Token
  final String sessionToken;

  /// 过期时间（秒级时间戳）
  ///
  /// 后端是字符串，这里统一解析为 int，方便直接比较和计算。
  final int expiredTime;

  /// COS Bucket 名称
  final String bucketName;

  /// 区域，例如 "ap-guangzhou"
  final String region;

  /// 后端建议的上传路径前缀，例如 "prod/chuanplus-order/h5-app/"
  final String uploadPath;

  /// COS 上传域名地址
  final String uploadUrl;

  /// 允许的 COS 操作列表
  final List<String> allowedActions;

  /// 资源路径，例如：
  /// qcs::cos:ap-guangzhou:uid/xxx:bucketName/prod/.../*
  final String resourcePath;

  /// 上传相关权限
  final StsPermissions permissions;

  StsTokenModel({
    required this.tmpSecretId,
    required this.tmpSecretKey,
    required this.sessionToken,
    required this.expiredTime,
    required this.bucketName,
    required this.region,
    required this.uploadPath,
    required this.uploadUrl,
    required this.allowedActions,
    required this.resourcePath,
    required this.permissions,
  });

  factory StsTokenModel.fromJson(Map<String, dynamic> json) {
    return StsTokenModel(
      tmpSecretId: json['tmpSecretId'] as String? ?? '',
      tmpSecretKey: json['tmpSecretKey'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      expiredTime: _parseInt(json['expiredTime']) ?? 0,
      bucketName: json['bucketName'] as String? ?? '',
      region: json['region'] as String? ?? '',
      uploadPath: json['uploadPath'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      allowedActions: _parseStringList(json['allowedActions']),
      resourcePath: json['resourcePath'] as String? ?? '',
      permissions: json['permissions'] is Map<String, dynamic>
          ? StsPermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : StsPermissions(
              canUpload: false,
              uploadDirectory: '',
              businessType: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tmpSecretId': tmpSecretId,
      'tmpSecretKey': tmpSecretKey,
      'sessionToken': sessionToken,
      'expiredTime': expiredTime,
      'bucketName': bucketName,
      'region': region,
      'uploadPath': uploadPath,
      'uploadUrl': uploadUrl,
      'allowedActions': allowedActions,
      'resourcePath': resourcePath,
      'permissions': permissions.toJson(),
    };
  }
}

/// 上传准备接口返回的数据模型，对应 /api/upload/prepare 的 data 字段。
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

  /// STS 凭证，可选（后端可顺带返回，前端少调一次 /api/sts/token）
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

  /// 是否是已完成（秒传）状态
  bool get isCompleted => status == 'COMPLETED';

  /// 是否是新上传
  bool get isNew => status == 'NEW';

  /// 是否是断点续传/已上传部分分片
  bool get isPartial => status == 'PARTIAL';

  /// 是否是正在上传但还没有任何分片（UPLOADING）
  bool get isUploading => status == 'UPLOADING';
}

/// 上传单个分片完成后的回调结果，对应 /api/upload/chunk/complete 的 data 字段。
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

  /// 是否已经上传全部分片，可以调用“合并分片”接口
  bool get isReadyToComplete => readyToComplete;
}

/// 整个文件合并完成后的结果，对应 /api/upload/complete 的 data 字段。
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

/// --------- 工具函数（仅在本文件内部使用） ---------

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const <String>[];
}

List<int> _parseIntList(dynamic value) {
  if (value is List) {
    return value.map((e) {
      if (e is int) return e;
      if (e is String) return int.tryParse(e) ?? 0;
      return 0;
    }).toList();
  }
  return const <int>[];
}
