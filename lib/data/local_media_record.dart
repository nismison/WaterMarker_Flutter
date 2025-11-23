// 一个本地媒体文件的索引记录
class LocalMediaRecord {
  final String path;
  final int size;
  final int mtime; // 毫秒时间戳
  final String? md5;
  final bool uploaded;
  final int firstSeenTs;
  final int? lastCheckTs;
  final int? lastUploadTs;
  final int errorCount;
  final String? lastError;

  LocalMediaRecord({
    required this.path,
    required this.size,
    required this.mtime,
    this.md5,
    required this.uploaded,
    required this.firstSeenTs,
    this.lastCheckTs,
    this.lastUploadTs,
    this.errorCount = 0,
    this.lastError,
  });

  LocalMediaRecord copyWith({
    int? size,
    int? mtime,
    String? md5,
    bool? uploaded,
    int? firstSeenTs,
    int? lastCheckTs,
    int? lastUploadTs,
    int? errorCount,
    String? lastError,
  }) {
    return LocalMediaRecord(
      path: path,
      size: size ?? this.size,
      mtime: mtime ?? this.mtime,
      md5: md5 ?? this.md5,
      uploaded: uploaded ?? this.uploaded,
      firstSeenTs: firstSeenTs ?? this.firstSeenTs,
      lastCheckTs: lastCheckTs ?? this.lastCheckTs,
      lastUploadTs: lastUploadTs ?? this.lastUploadTs,
      errorCount: errorCount ?? this.errorCount,
      lastError: lastError ?? this.lastError,
    );
  }

  factory LocalMediaRecord.fromMap(Map<String, Object?> map) {
    return LocalMediaRecord(
      path: map['path'] as String,
      size: map['size'] as int,
      mtime: map['mtime'] as int,
      md5: map['md5'] as String?,
      uploaded: (map['uploaded'] as int) == 1,
      firstSeenTs: map['first_seen_ts'] as int,
      lastCheckTs: map['last_check_ts'] as int?,
      lastUploadTs: map['last_upload_ts'] as int?,
      errorCount: (map['error_count'] as int?) ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'path': path,
      'size': size,
      'mtime': mtime,
      'md5': md5,
      'uploaded': uploaded ? 1 : 0,
      'first_seen_ts': firstSeenTs,
      'last_check_ts': lastCheckTs,
      'last_upload_ts': lastUploadTs,
      'error_count': errorCount,
      'last_error': lastError,
    };
  }
}
