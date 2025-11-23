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
/// 全局统一：
/// - 初始化路由 / 配置
/// - 首帧后启动真实初始化流程
/// - 展示 SplashScreen（动画）
/// - 全局修正 MediaQuery，适配国产 ROM 底部小白条
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
    _initFuture = _startInitAfterFirstFrame();
  }

  /// 确保 Splash 先渲染，再启动逻辑
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

  /// 统一初始化逻辑
  Future<void> _initApp() async {
    final appConfigProvider = context.read<AppConfigProvider>();
    final userProvider = context.read<UserProvider>();
    final imagePickerProvider = context.read<ImagePickerProvider>();

    // 1. 路由初始化
    _splashController.updateMessage('正在初始化路由...');
    AppRouter.setupRouter();

    // 2. 设置后端 BaseUrl
    _splashController.updateMessage('正在配置网络...');
    HttpClient.setBaseUrl('https://api.zytsy.icu');

    // 3. 加载配置
    _splashController.updateMessage('正在加载配置...');
    await _loadAppConfig(appConfigProvider);

    // 4. 用户列表
    _splashController.updateMessage('正在加载用户列表...');
    await userProvider.fetchUserList();
    imagePickerProvider.updateUser(userProvider.users.first);

    // 5. 异步启动图片同步
    _startScanImages();
  }

  Future<void> _loadAppConfig(AppConfigProvider appConfigProvider) async {
    await appConfigProvider.loadLocalConfig();
    try {
      await appConfigProvider.refreshConfig();
    } catch (e) {
      debugPrint("AppConfig: 远端刷新失败，使用本地缓存: $e");
    }
  }

  Future<void> _startScanImages() async {
    final appConfig = context.read<AppConfigProvider>();
    if (!appConfig.config!.autoUpload.imageEnable) return;

    final hasAll = await StorageUtil.hasAllFilesAccess();
    if (!hasAll) {
      _splashController.updateMessage('未授予文件访问权限，跳过自动同步');
      return;
    }

    const isUpload = false;

    final prodService = ImageSyncService(isUpload: isUpload);
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
        final isReady = snapshot.connectionState == ConnectionState.done;

        final Widget content = isReady
            ? const WatermarkApp()
            : MaterialApp(
                debugShowCheckedModeBanner: false,
                home: SplashScreen(controller: _splashController),
              );

        // =============================================================
        // ★ 全局适配国产 ROM 底部小白条（关键改造）
        // - 强制所有页面使用 viewPadding，忽略部分 ROM 错误的 padding / insets
        // - 解决 MIUI/EMUI/ColorOS 手势导航条遮挡问题
        // =============================================================
        final mq = MediaQuery.of(context);
        final fixedData = mq.copyWith(
          padding: mq.viewPadding,
          viewPadding: mq.viewPadding,
        );

        return MediaQuery(data: fixedData, child: content);
      },
    );
  }
}
