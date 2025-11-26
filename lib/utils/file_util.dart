import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

/// 文件工具：
/// - fileMd5: 流式读取文件，计算 32 位大写 hex MD5
/// - bytesMd5: 已有内存数据时计算 MD5
class FileUtil {
  /// 计算文件 MD5（32 位大写 hex），默认在单独 Isolate 中执行
  static Future<String> fileMd5(
      String path, {
        bool useIsolate = true,
      }) async {
    if (!useIsolate) {
      return _fileMd5Internal(path);
    }
    return Isolate.run(() => _fileMd5Internal(path));
  }

  /// 已有 bytes 时直接计算 MD5
  static String bytesMd5(List<int> bytes) {
    final digest = md5.convert(bytes);
    return digest.toString(); // 小写 hex
  }

  static Future<String> _fileMd5Internal(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw ArgumentError('File not found: $path');
    }

    final stream = file.openRead();
    final digest = await md5.bind(stream).first;
    return digest.toString().toUpperCase();
  }
}
