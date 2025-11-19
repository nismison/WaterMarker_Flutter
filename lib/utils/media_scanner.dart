import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class MediaScanner {
  static const MethodChannel _channel = MethodChannel('media_scanner');

  /// 通知 Android 扫描指定文件，使其立即出现在相册
  ///
  /// :param path: 图片或视频完整路径
  /// :returns: Future<bool>
  static Future<bool> scanFile(String path) async {
    try {
      final bool result = await _channel.invokeMethod('scanFile', {
        'path': path,
      });
      return result;
    } catch (e) {
      debugPrint("媒体扫描失败: $e");
      return false;
    }
  }
}
