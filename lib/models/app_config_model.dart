/// 解析后的 App 配置模型。
/// 之所以单独建模型，是为了避免上层直接操作 Map，提升可维护性。
class AppConfigModel {
  final AutoUploadConfig autoUpload;

  AppConfigModel({required this.autoUpload});

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      autoUpload: AutoUploadConfig.fromJson(json['auto_upload']),
    );
  }

  Map<String, dynamic> toJson() => {'auto_upload': autoUpload.toJson()};
}

class AutoUploadConfig {
  final List<String> excludeDeviceModels;
  final bool imageEnable;
  final bool videoEnable;
  final int maxUploadNum;
  final int maxUploadSize;

  AutoUploadConfig({
    required this.excludeDeviceModels,
    required this.imageEnable,
    required this.videoEnable,
    required this.maxUploadNum,
    required this.maxUploadSize,
  });

  factory AutoUploadConfig.fromJson(Map<String, dynamic> json) {
    return AutoUploadConfig(
      excludeDeviceModels: List<String>.from(
        json['exclude_device_models'] ?? [],
      ),
      imageEnable: json['image_enable'] ?? false,
      videoEnable: json['video_enable'] ?? false,
      maxUploadNum: json['max_upload_num'] ?? 1,
      maxUploadSize: json['max_upload_size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'exclude_device_models': excludeDeviceModels,
    'image_enable': imageEnable,
    'video_enable': videoEnable,
    'max_upload_num': maxUploadNum,
    'max_upload_size': maxUploadSize,
  };
}
