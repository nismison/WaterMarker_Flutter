// lib/utils/storage_util.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class StorageUtil {
  // 目标路径（你指定的路径）
  static const String _targetDirPath =
      '/storage/emulated/0/lebang/waterImages/';

  /// 保存多个图片到固定目录
  ///
  /// :param imagePaths: 本地原始图片路径列表（String[]）
  /// :return: List<String> 成功保存后的新路径列表
  /// :throws: Exception when permission denied or save failed
  static Future<List<String>> saveImages(List<String> imagePaths) async {
    // 检查并申请必要权限
    final hasPermission = await _ensureStoragePermission();
    if (!hasPermission) {
      throw Exception("没有存储权限，无法保存图片");
    }

    final targetDir = Directory(_targetDirPath);

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final List<String> savedPaths = [];

    for (final srcPath in imagePaths) {
      final srcFile = File(srcPath);

      if (!await srcFile.exists()) {
        print("源文件不存在: $srcPath，跳过");
        continue;
      }

      String fileName = p.basename(srcPath);
      String targetPath = p.join(_targetDirPath, fileName);

      // 避免覆盖已存在文件
      if (await File(targetPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = p.extension(fileName);
        final baseName = p.basenameWithoutExtension(fileName);

        targetPath = p.join(_targetDirPath, "${baseName}_$timestamp$ext");
      }

      // 执行复制
      try {
        await srcFile.copy(targetPath);
        print("已保存: $targetPath");
        savedPaths.add(targetPath);
      } catch (e) {
        print("保存失败: $e");
      }
    }

    if (savedPaths.isEmpty) {
      throw Exception("所有保存操作失败，检查路径或权限");
    }

    return savedPaths;
  }

  /// 内部方法：确保有保存权限
  static Future<bool> _ensureStoragePermission() async {
    // Andriod 11+ 推荐使用 manageExternalStorage
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // 尝试申请
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }

    // 如果还是不行（比如 Android 10 一下），再尝试普通权限
    if (await Permission.storage.isGranted) {
      return true;
    }

    final basicStatus = await Permission.storage.request();
    return basicStatus.isGranted;
  }
}
