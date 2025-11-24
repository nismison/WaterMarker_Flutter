class LocalMediaRecord {
  final String path;
  final bool uploaded;

  const LocalMediaRecord({
    required this.path,
    required this.uploaded,
  });

  LocalMediaRecord copyWith({
    bool? uploaded,
  }) {
    return LocalMediaRecord(
      path: path,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  factory LocalMediaRecord.fromMap(Map<String, Object?> map) {
    return LocalMediaRecord(
      path: map['path'] as String,
      uploaded: (map['uploaded'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'path': path,
      'uploaded': uploaded ? 1 : 0,
    };
  }
}
