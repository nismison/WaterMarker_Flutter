import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

/// 文件工具：
/// - fileMd5: 流式读取文件，计算 32 位大写 hex MD5
/// - bytesMd5: 已有内存数据时计算 MD5
class FileUtil {
  /// 计算文件 MD5（32 位大写 hex），默认在单独 Isolate 中执行
  static Future<String> fileMd5(String path, {bool useIsolate = true}) async {
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

  /// 基于 path + size + mtime 的“快速文件指纹”
  ///
  /// 注意：这是“文件实例指纹”，不是严格意义上的内容指纹。
  /// - 不读取文件内容，性能开销极小
  /// - 适合作为缓存 key / 变更检测依据
  /// - 不适合作为跨设备/长期的“内容唯一 ID”
  static Future<String> fileFingerprint(File file) async {
    final stat = await file.stat();

    // 用 path + size + modified(微秒) 拼成一个字符串
    // 中间用分隔符防止歧义
    final metaString = [
      file.path,
      stat.size.toString(),
      stat.modified.microsecondsSinceEpoch.toString(),
    ].join('|');

    final bytes = utf8.encode(metaString);
    final digest = md5.convert(bytes);
    return digest.toString().toUpperCase(); // 32 位大写 HEX
  }
}

extension FileFingerprintExtension on File {
  /// 基于 path + size + mtime 的“快速文件指纹”
  ///
  /// 注意：这是“文件实例指纹”，不是严格意义上的内容指纹。
  /// 只是对 FileUtil.fileFingerprint 的一层语法糖封装。
  Future<String> fingerprint() {
    return FileUtil.fileFingerprint(this);
  }

  /// 如果你也想顺手拿到内容 MD5，可以顺便包一层：
  Future<String> md5({bool useIsolate = true}) {
    return FileUtil.fileMd5(path, useIsolate: useIsolate);
  }
}
