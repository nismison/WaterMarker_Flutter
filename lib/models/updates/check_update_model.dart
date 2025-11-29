// lib/models/check_update_model.dart

class CheckUpdateModel {
  final String version;
  final String nowUrl;

  CheckUpdateModel({
    required this.version,
    required this.nowUrl,
  });

  factory CheckUpdateModel.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);

    return CheckUpdateModel(
      version: copy.remove("version") as String,
      nowUrl: copy.remove("now_url") as String,
    );
  }

  Map<String, dynamic> toJson() => {
    "version": version,
    "now_url": nowUrl,
  };
}
