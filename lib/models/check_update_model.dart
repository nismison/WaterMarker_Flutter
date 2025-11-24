// lib/models/check_update_model.dart

class CheckUpdateModel {
  final String version;
  final String nowUrl;

  // config 内容不定，因此保存为 Map
  final Map<String, dynamic> extraConfig;

  CheckUpdateModel({
    required this.version,
    required this.nowUrl,
    required this.extraConfig,
  });

  factory CheckUpdateModel.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);

    return CheckUpdateModel(
      version: copy.remove("version") as String,
      nowUrl: copy.remove("now_url") as String,
      extraConfig: copy, // 剩下的全部是配置
    );
  }

  Map<String, dynamic> toJson() => {
    "version": version,
    "now_url": nowUrl,
    ...extraConfig,
  };
}
