import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:watermarker_v2/api/app_config_api.dart';      // 提供 AppConfigApi
import 'package:watermarker_v2/models/app_config_model.dart';   // 提供 AppConfigModel

/// Provider 用于全局维护 AppConfig 状态。
class AppConfigProvider extends ChangeNotifier {
  final AppConfigApi _api = AppConfigApi();

  AppConfigModel? _config;

  AppConfigModel? get config => _config;

  /// 初始化：优先加载本地缓存，然后可选择发起远端刷新
  Future<void> loadLocalConfig() async {
    final local = await _api.loadLocalConfig();
    if (local != null) {
      _config = local;
      debugPrint('AppConfig: 本地配置加载成功: ${jsonEncode(local.toJson())}');
      notifyListeners();
    }
  }

  /// 从远程刷新配置并同步到 Provider
  Future<void> refreshConfig() async {
    final remote = await _api.fetchAppConfig();
    _config = remote;
    debugPrint('AppConfig: 远程配置刷新成功: ${jsonEncode(remote.toJson())}');
    notifyListeners();
  }

  /// 外部直接设置（一般不会用）
  void setConfig(AppConfigModel config) {
    _config = config;
    notifyListeners();
  }

  /// 是否已经加载完成配置（用于页面判断）
  bool get isReady => _config != null;
}
