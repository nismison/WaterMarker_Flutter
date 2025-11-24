class LocalMediaRecord {
  final String assetId;
  final bool uploaded;

  const LocalMediaRecord({
    required this.assetId,
    required this.uploaded,
  });

  LocalMediaRecord copyWith({
    bool? uploaded,
  }) {
    return LocalMediaRecord(
      assetId: assetId,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  factory LocalMediaRecord.fromMap(Map<String, Object?> map) {
    return LocalMediaRecord(
      assetId: map['asset_id'] as String,
      uploaded: (map['uploaded'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'asset_id': assetId,
      'uploaded': uploaded ? 1 : 0,
    };
  }
}
