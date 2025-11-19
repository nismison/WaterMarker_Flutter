import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class StoragePermissionUtil {
  static const MethodChannel _channel =
  MethodChannel('external_storage_permission');

  // =============================================================
  // 所有文件访问权限（Android 11+）
  // =============================================================

  static Future<bool> hasAllFilesPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.manageExternalStorage.status;
    return status.isGranted;
  }

  static Future<bool> requestAllFilesPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static Future<void> openManageAllFilesSettings() async {
    try {
      await _channel.invokeMethod("openManageAllFilesPage");
    } catch (e) {
      print("跳转所有文件访问权限页面失败: $e");
    }
  }

  static Future<bool> ensureAllFilesPermission() async {
    if (await hasAllFilesPermission()) return true;

    await openManageAllFilesSettings();
    return false;
  }

  // =============================================================
  // 摄像头权限
  // =============================================================

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureCameraPermission() async {
    if (await hasCameraPermission()) return true;
    return await requestCameraPermission();
  }

  // =============================================================
  // 图片访问权限（Photo Access）
  // Android 13+: READ_MEDIA_IMAGES
  // Android <=12: READ_EXTERNAL_STORAGE
  // iOS: Photos 权限，包括 limited / full access
  // =============================================================

  /// 是否拥有访问图片权限
  static Future<bool> hasImageAccessPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    Permission permission = _getImagePermissionForPlatform();
    final status = await permission.status;

    return status.isGranted || status.isLimited;
  }

  /// 请求图片访问权限
  static Future<bool> requestImageAccessPermission() async {
    Permission permission = _getImagePermissionForPlatform();
    final status = await permission.request();

    return status.isGranted || status.isLimited;
  }

  /// 若未授权 → 自动请求
  static Future<bool> ensureImageAccessPermission() async {
    if (await hasImageAccessPermission()) return true;
    return await requestImageAccessPermission();
  }

  /// 根据平台和 Android 版本返回正确的权限类型
  static Permission _getImagePermissionForPlatform() {
    if (Platform.isIOS) {
      return Permission.photos;
    }

    if (Platform.isAndroid) {
      // Android 13+
      if (Platform.version.startsWith("13") ||
          Platform.version.startsWith("14")) {
        return Permission.photos;
      }

      // Android 12 及以下
      return Permission.storage;
    }

    return Permission.photos; // fallback
  }
}
