// lib/pages/app_root.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/http_client.dart';
import '../providers/app_config_provider.dart';
import '../providers/image_picker_provider.dart';
import '../providers/user_provider.dart';
import '../router.dart';
import '../services/image_sync_service.dart';
import '../utils/storage_util.dart';
import 'splash_page.dart';
import 'watermark_app.dart';

/// App 根组件：
/// 1. 统一管理启动初始化逻辑：
///    - 路由初始化
///    - 设置后端 BaseUrl
///    - 加载 AppConfig
///    - 启动图片同步
/// 2. 在初始化期间展示 SplashScreen（Lottie 动画 + 动态文字）
///
/// 为了让动画尽快显示：
/// - 首帧渲染出来后再开始执行真正的初始化逻辑
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final Future<void> _initFuture;
  late final SplashController _splashController;

  @override
  void initState() {
    super.initState();
    _splashController = SplashController(initialMessage: '正在启动应用...');
    _initFuture = _startInitAfterFirstFrame(); // 首帧之后再真正初始化
  }

  /// 确保先渲染出 Splash，再执行初始化任务
  Future<void> _startInitAfterFirstFrame() {
    final completer = Completer<void>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _initApp();
      } catch (e, s) {
        debugPrint('App init error: $e\n$s');
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// App 启动时需要执行的初始化逻辑统一放在这里
  Future<void> _initApp() async {
    // 0. 获取 Provider
    final appConfigProvider = context.read<AppConfigProvider>();
    final userProvider = context.read<UserProvider>();
    final imagePickerProvider = context.read<ImagePickerProvider>();

    // 1. 初始化路由
    _splashController.updateMessage('正在初始化...');
    AppRouter.setupRouter();

    // 2. 设置后端 BaseUrl
    _splashController.updateMessage('正在配置网络...');
    HttpClient.setBaseUrl('https://api.zytsy.icu');

    // 3. 加载 App 配置
    _splashController.updateMessage('正在加载配置...');
    await _loadAppConfig(appConfigProvider);

    // 4. 获取用户列表
    _splashController.updateMessage('正在加载用户列表...');
    await userProvider.fetchUserList();
    debugPrint('用户列表: ${userProvider.users}');
    imagePickerProvider.updateUser(userProvider.users.first);

    // 5. 初始化完成后，启动图片同步（不阻塞 Splash 动画）
    _startScanImages();
  }

  /// 原来的 loadAppConfig 逻辑
  Future<void> _loadAppConfig(AppConfigProvider appConfigProvider) async {
    // 初始化 AppConfigProvider 并加载本地缓存
    await appConfigProvider.loadLocalConfig();

    // 刷新 AppConfigProvider
    try {
      await appConfigProvider.refreshConfig();
    } catch (e) {
      debugPrint("AppConfig: 远端配置刷新失败，已回退至本地缓存: $e");
    }
  }

  /// 原来的 startScanImages 逻辑，搬到这里统一管理
  Future<void> _startScanImages() async {
    final appConfig = context.read<AppConfigProvider>();
    if (!appConfig.config!.autoUpload.imageEnable) {
      return;
    }

    // 检查文件访问权限
    final hasAll = await StorageUtil.hasAllFilesAccess();
    if (!hasAll) {
      _splashController.updateMessage('未授予文件访问权限，跳过自动同步');
      return;
    }

    /// 测试模式：只压接口，不动 SQLite
    /// 正常模式：带本地索引的增量同步
    const isTest = false;
    const isUpload = false;

    final prodService = ImageSyncService(isTest: isTest, isUpload: isUpload);
    await prodService.syncAllImages(appConfig);
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // 初始化未完成：显示带 Lottie 动画的开屏页
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(controller: _splashController),
          );
        }

        // 初始化完成：进入真正的应用
        return const WatermarkApp();
      },
    );
  }
}
