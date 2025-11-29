import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:watermarker_v2/api/updates/check_update_api.dart';
import 'package:watermarker_v2/api/uploads/download_api.dart';

class UpdateUtil {
  static const MethodChannel _installChannel = MethodChannel("apk_installer");

  // ============================================================
  // 1. 检查服务器版本，判断是否需要更新
  // ============================================================

  /// 返回：
  /// {
  ///   "needUpdate": true/false,
  ///   "latestVersion": "1.3.6",
  ///   "downloadUrl": "/api/download/app-release.apk"
  /// }
  static Future<Map<String, dynamic>> checkUpdate(String currentVersion) async {
    final check = await CheckUpdateApi().fetchLatest();

    final latestVersion = check.version;
    final nowUrl = check.nowUrl;

    final need = _compareVersion(latestVersion, currentVersion) == 1;

    return {
      "needUpdate": need,
      "latestVersion": latestVersion,
      "downloadUrl": nowUrl,
    };
  }

  /// 版本比较：1(new > old), 0(=), -1(new < old)
  static int _compareVersion(String newV, String oldV) {
    final a = _parseVersion(newV);
    final b = _parseVersion(oldV);

    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  /// "1.3.6+12" -> [1, 3, 6]
  static List<int> _parseVersion(String v) {
    final core = v.split('+').first;
    final parts = core.split('.');
    final list = List<int>.filled(3, 0);

    for (int i = 0; i < parts.length && i < 3; i++) {
      list[i] = int.tryParse(parts[i]) ?? 0;
    }

    return list;
  }

  // ============================================================
  // 2. 下载 APK + 安装 APK
  // ============================================================

  /// 下载 APK 到临时目录，然后安装
  static Future<void> downloadAndInstallApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await DownloadApi().downloadFile(
      downloadUrl,
      onProgress: onProgress,
    );

    final path = await _saveApk(bytes, _filename(downloadUrl));

    await _installChannel.invokeMethod("installApk", {"filePath": path});
  }

  static Future<String> _saveApk(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$fileName");
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static String _filename(String url) {
    return url.split('/').last;
  }
}
