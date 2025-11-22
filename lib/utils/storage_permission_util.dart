import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class AppPermissions {
  static const MethodChannel _channel =
  MethodChannel('external_storage_permission');

  // ============================================================
  // 1. 媒体访问权限（相册）—— 国产 ROM 兼容核心
  //    只用 requestPermissionExtend，不再用 getPermissionState
  // ============================================================

  /// 检查是否有相册/媒体访问权限
  /// 说明：
  /// - Android 上 requestPermissionExtend() 既可“查状态”也可“拉起授权”
  /// - 已授权时不会再次弹窗，只返回当前 PermissionState
  static Future<bool> hasGalleryPermission() async {
    if (!Platform.isAndroid) return true;

    final PermissionState state =
    await PhotoManager.requestPermissionExtend();

    // isAuth: 完全授权
    // hasAccess: “部分访问”/“仅选中的照片”等情况
    return state.isAuth || state.hasAccess;
  }

  /// 确保有相册权限（进入相册页面前用这个）
  static Future<bool> ensureGalleryPermission() async {
    if (!Platform.isAndroid) return true;

    // 第一次尝试（可能弹授权窗）
    final PermissionState state =
    await PhotoManager.requestPermissionExtend();

    if (state.isAuth || state.hasAccess) {
      return true;
    }

    // 用户拒绝了，或者 ROM 做了骚操作 → 跳系统设置
    await PhotoManager.openSetting();

    // 从设置页返回后再查一次
    final PermissionState retry =
    await PhotoManager.requestPermissionExtend();

    return retry.isAuth || retry.hasAccess;
  }

  // ============================================================
  // 2. 相机权限（permission_handler）
  // ============================================================

  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // ============================================================
  // 3. 所有文件访问权限（MANAGE_EXTERNAL_STORAGE）
  // ============================================================

  static int _apiLevel() {
    try {
      return int.parse(Platform.version.split('.').first);
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> hasAllFilesPermission() async {
    if (!Platform.isAndroid) return true;

    final api = _apiLevel();
    if (api < 30) {
      // Android 10 及以下只有传统 storage
      return await Permission.storage.isGranted;
    }

    // Android 11+ 使用 MANAGE_EXTERNAL_STORAGE
    return await Permission.manageExternalStorage.isGranted;
  }

  static Future<bool> ensureAllFilesPermission() async {
    if (!Platform.isAndroid) return true;

    final api = _apiLevel();

    if (api < 30) {
      final st = await Permission.storage.request();
      return st.isGranted;
    }

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // 调用你 Kotlin 里的 MethodChannel，跳“允许管理所有文件”页面
    try {
      await _channel.invokeMethod("openManageAllFilesPage");
    } catch (e) {
      print("openManageAllFilesPage 调用失败: $e");
    }

    // 用户从设置返回后再检查一次
    return await Permission.manageExternalStorage.isGranted;
  }

  // ============================================================
  // 4. 图片选择器入口（推荐统一用这个）
  // ============================================================

  /// 图片选择入口常用权限：
  /// - 相册权限（国产 ROM 兼容）
  /// - 可选：相机权限（如果页面里有拍照按钮就设 needCamera = true）
  static Future<bool> ensureMediaAndCameraForPicker({
    bool needCamera = false,
  }) async {
    final ok = await ensureGalleryPermission();
    if (!ok) return false;

    if (needCamera) {
      final camOk = await ensureCameraPermission();
      return camOk;
    }

    return true;
  }
}
