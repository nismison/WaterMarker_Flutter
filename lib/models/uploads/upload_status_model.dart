class UploadStatus {
  final bool uploaded;

  UploadStatus({required this.uploaded});

  factory UploadStatus.fromJson(Map<String, dynamic> json) {
    return UploadStatus(
      uploaded: json['uploaded'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'uploaded': uploaded,
  };
}
