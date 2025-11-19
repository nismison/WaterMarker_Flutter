// lib/utils/storage_util.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class StorageUtil {
  // 目标路径（你指定的路径）
  static const String _targetDirPath =
      '/storage/emulated/0/lebang/waterImages/';

  // Android 端用于 MediaStore 写入的通道
  static const MethodChannel _mediaStoreChannel = MethodChannel("media_store");

  /// 保存多个图片到固定目录
  static Future<List<String>> saveImages(List<String> imagePaths) async {
    final bool allowed = await _ensureStoragePermission();
    if (!allowed) throw Exception("没有存储权限，无法保存图片");

    final Directory targetDir = Directory(_targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final int cpuCores = Platform.numberOfProcessors;
    final int maxConcurrent = _computeConcurrency(cpuCores);

    debugPrint("设备 CPU: $cpuCores, 动态并发数: $maxConcurrent");

    final List<Future<String?>> tasks = [];
    for (final path in imagePaths) {
      tasks.add(_copyAndInsert(path));
    }

    final List<String?> results = await _runWithConcurrencyLimit(
      tasks,
      maxConcurrent,
    );

    final saved = results.whereType<String>().toList();
    if (saved.isEmpty) throw Exception("所有保存操作失败");

    return saved;
  }

  /// 内部方法：确保有保存权限
  static Future<bool> _ensureStoragePermission() async {
    // Android 11+ 推荐使用 manageExternalStorage
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }

    // Android 10 以下 fallback 到 storage
    if (await Permission.storage.isGranted) {
      return true;
    }

    final basicStatus = await Permission.storage.request();
    return basicStatus.isGranted;
  }

  /// 单个图片的复制 + 注册到媒体库
  static Future<String?> _copyAndInsert(String srcPath) async {
    final File src = File(srcPath);
    if (!await src.exists()) {
      debugPrint("源文件不存在: $srcPath");
      return null;
    }

    final String targetPath = await _uniqueTargetPath(srcPath);

    try {
      await src.copy(targetPath);
      debugPrint("已保存: $targetPath");

      final bool ok = await _insertToMediaStore(targetPath);
      debugPrint("MediaStore 插入状态: $ok");

      return ok ? targetPath : null;
    } catch (e) {
      debugPrint("保存失败: $e");
      return null;
    }
  }

  /// 直接写入 MediaStore，100% 出现在相册
  static Future<bool> _insertToMediaStore(String path) async {
    try {
      final result = await _mediaStoreChannel.invokeMethod(
        "insertImageToMediaStore",
        {"path": path},
      );
      return result == true;
    } catch (e) {
      debugPrint("MediaStore 调用失败: $e");
      return false;
    }
  }

  /// 为目标文件生成不重复的路径
  static Future<String> _uniqueTargetPath(String srcPath) async {
    final String fileName = p.basename(srcPath);
    String targetPath = p.join(_targetDirPath, fileName);

    if (!await File(targetPath).exists()) return targetPath;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);

    return p.join(_targetDirPath, "${base}_$timestamp$ext");
  }

  /// 按最大并发数执行 Future 列表（I/O Friendly）
  static Future<List<T>> _runWithConcurrencyLimit<T>(
      List<Future<T>> tasks,
      int limit,
      ) async {
    final List<T> results = List.filled(tasks.length, null as T);
    int index = 0;

    Future<void> worker() async {
      while (true) {
        int currentIndex;
        if (index >= tasks.length) return;
        currentIndex = index;
        index++;

        results[currentIndex] = await tasks[currentIndex];
      }
    }

    final List<Future> workers = List.generate(limit, (_) => Future(worker));
    await Future.wait(workers);
    return results;
  }

  /// 根据 CPU 核心数动态并发控制
  static int _computeConcurrency(int cpu) {
    if (cpu <= 4) return 2;
    if (cpu <= 8) return 4;
    return 6;
  }
}
