// lib/utils/storage_util.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

class StorageUtil {
  // 目标路径（你指定的路径）
  static const String _targetDirPath =
      '/storage/emulated/0/lebang/waterImages/';

  // Android 端用于 MediaStore 写入的通道
  static const MethodChannel _mediaStoreChannel = MethodChannel("media_store");

  // Android 端用于存储权限相关的通道（对应 MainActivity 里的 CHANNEL_PERMISSION）
  static const MethodChannel _permissionChannel = MethodChannel(
    "external_storage_permission",
  );

  /// 静默检查：是否已经拥有“所有文件访问”权限
  ///
  /// - 不会触发系统授权弹窗
  /// - 不会跳转到设置页
  /// - 对应原生 MainActivity.hasAllFilesPermission()
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool? granted = await _permissionChannel.invokeMethod<bool>(
        'hasAllFilesPermission',
      );
      return granted ?? false;
    } catch (e) {
      debugPrint('hasAllFilesAccess 调用失败: $e');
      // 兜底：如果原生调用异常，就返回 false，让上层自行处理
      return false;
    }
  }

  /// 显式“请求”所有文件访问权限：通过跳转设置页让用户手动开启
  ///
  /// 注意：
  /// - 这里只负责打开系统设置页面，不会等待用户操作结果
  /// - 通常配合 [hasAllFilesAccess] 使用：跳转后用户返回，再重新检查
  static Future<void> openAllFilesPermissionSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _permissionChannel.invokeMethod('openManageAllFilesPage');
    } catch (e) {
      debugPrint('openAllFilesPermissionSettings 调用失败: $e');
    }
  }

  /// 保存多个图片到固定目录
  static Future<List<String>> saveImages(List<String> imagePaths) async {
    final bool allowed = await _ensureStoragePermission();
    if (!allowed) {
      // 此时已经尝试跳转过设置页（Android），直接抛异常让上层提示用户
      throw Exception('没有存储权限，请在系统设置中开启“允许访问所有文件”后重试');
    }

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
  ///
  /// 规则：
  /// - 先静默检查 [hasAllFilesAccess]；
  /// - 如果没有权限，则通过 [openAllFilesPermissionSettings] 跳转设置页；
  /// - 跳转后直接返回 false（因为此时无法知道用户是否勾选了权限）。
  static Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) {
      // iOS 这里可以根据需要改成 true/false，目前直接放行
      return true;
    }

    // 静默检查，不触发任何 UI
    if (await hasAllFilesAccess()) {
      return true;
    }

    // 真正“请求权限”的时机：跳转到设置页，让用户手动开启
    await openAllFilesPermissionSettings();

    // 无法同步得知用户是否授权，返回 false，交由上层处理
    return false;
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

  /// 直接写入 MediaStore，确保出现在系统相册
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
