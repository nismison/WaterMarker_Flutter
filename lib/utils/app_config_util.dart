import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'http/http_client.dart';

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

/// 工具类用于请求远端配置并持久化。
class AppConfigUtil {
  static const String _prefsKey = 'app_config';

  /// 从远端请求，并写入 SharedPreferences。
  /// AppConfigProvider 会根据此方法的返回值自动更新全局状态。
  static Future<AppConfigModel> fetchAppConfig() async {
    final res = await HttpClient().get('/api/app_config');

    if (res is! Map || res['success'] != true) {
      final errMsg = res is Map ? res['error']?.toString() : 'Unknown error';
      throw AppNetworkException(errMsg ?? '请求失败');
    }

    final data = res['data'] as Map<String, dynamic>;
    final model = AppConfigModel.fromJson(data);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(model.toJson()));

    if (kDebugMode) {
      debugPrint('AppConfig saved: ${jsonEncode(model.toJson())}');
    }

    return model;
  }

  /// 从 SharedPreferences 读取已缓存的配置信息。
  static Future<AppConfigModel?> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return null;

    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AppConfigModel.fromJson(data);
  }
}
