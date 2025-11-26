// lib/models/sts_token_model.dart

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

/// COS STS 临时凭证数据模型，对应后端 data 字段。
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
          ? StsPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      )
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }
}
