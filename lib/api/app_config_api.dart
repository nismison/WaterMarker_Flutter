import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermarker_v2/api/base/api_client.dart';
import 'package:watermarker_v2/models/app_config_model.dart';

class AppConfigApi extends ApiClient {
  static const String _prefsKey = 'app_config';

  /// 远程拉取配置 + 写入本地缓存
  Future<AppConfigModel> fetchAppConfig() async {
    // safeCall(() => dio.get(...)) 会自动：
    // - 捕获网络异常
    // - 捕获 success=false 的业务异常
    // - 抽取并返回 "data" 字段（Map<String, dynamic>）
    final Map<String, dynamic> data = await safeCall(() {
      return dio.get('/api/app_config');
    });

    final model = AppConfigModel.fromJson(data);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(model.toJson()));

    return model;
  }

  /// 从 SharedPreferences 读取已缓存的配置信息。
  Future<AppConfigModel?> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppConfigModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
