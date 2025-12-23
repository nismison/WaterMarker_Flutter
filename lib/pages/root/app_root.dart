import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:watermarker_v2/api/base/http_client.dart';
import 'package:watermarker_v2/background/background_fetch_manager.dart';
import 'package:watermarker_v2/pages/root/main.dart';
import 'package:watermarker_v2/pages/root/splash_page.dart';
import 'package:watermarker_v2/providers/app_config_provider.dart';
import 'package:watermarker_v2/providers/fm_config_provider.dart';
import 'package:watermarker_v2/providers/image_picker_provider.dart';
import 'package:watermarker_v2/providers/user_provider.dart';
import 'package:watermarker_v2/router.dart';
import 'package:watermarker_v2/services/image_share_service.dart';
import 'package:watermarker_v2/services/image_sync_service.dart';
import 'package:watermarker_v2/utils/update_util.dart';

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

  // 图片分享服务
  final ImageShareService _imageShareService = ImageShareService();
  final ShareHandlerPlatform _shareHandler = ShareHandlerPlatform.instance;
  StreamSubscription<SharedMedia>? _subscription;

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
    final fmConfig = context.read<FmConfigProvider>();

    // 路由初始化（仍然保留，供全局 Fluro 使用）
    _splashController.updateMessage('正在初始化路由...');
    AppRouter.setupRouter();

    // 设置后端 BaseUrl
    _splashController.updateMessage('正在配置网络...');
    // HttpClient.setBaseUrl('http://192.168.1.9:5001');

    // 加载配置
    _splashController.updateMessage('正在加载配置...');
    await _loadAppConfig(appConfigProvider);

    // 用户列表
    _splashController.updateMessage('正在加载用户列表...');
    await userProvider.fetchUserList();
    imagePickerProvider.updateUser(userProvider.users.first);

    _splashController.updateMessage('正在初始化数据库...');
    // TODO: 清空表数据
    // await DatabaseUtil.clearTable();

    _splashController.updateMessage('正在检查更新...');
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final result = await UpdateUtil.checkUpdate(currentVersion);

    if (result["needUpdate"]) {
      _splashController.updateMessage('正在下载更新...');
      debugPrint("[Update] 发现新版本：${result['latestVersion']}");
      debugPrint("[Update] 下载地址：${result['downloadUrl']}");
      // TODO: 下载安装包
      // await UpdateUtil.downloadAndInstallApk(
      //   result["downloadUrl"],
      //   onProgress: (v) {
      //     _splashController.updateMessage("下载进度：${(v * 100).toStringAsFixed(1)}%");
      //   },
      // );
    } else {
      debugPrint("[Update] 当前已是最新版本: $currentVersion");
    }

    if (!kDebugMode) {
      debugPrint("[BackgroundFetchManager] 开始初始化");
      await BackgroundFetchManager.instance.stop();
      await BackgroundFetchManager.instance.init(
        minimumFetchIntervalMinutes: 15, // 期望每 15 分钟触发一次
      );
      debugPrint("[BackgroundFetchManager] 初始化完成");
    }

    // 测试数据
    fmConfig.setUserInfo(userProvider.users.first);

    // 初始化图片分享服务
    _initShareHandler();

    // 异步启动图片同步
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

    const isUpload = true;

    final prodService = ImageSyncService(isUpload: isUpload);
    await prodService.syncAllImages(appConfig.config);
  }

  Future<void> _initShareHandler() async {
    debugPrint('[AppRoot] initPlatformState start');

    // 1. 冷启动：通过“分享”启动 App 的场景
    SharedMedia? initialMedia;
    try {
      initialMedia = await _shareHandler.getInitialSharedMedia();
      debugPrint('[AppRoot] getInitialSharedMedia -> $initialMedia');
    } catch (e, stack) {
      debugPrint('[AppRoot] getInitialSharedMedia error: $e\n$stack');
    }

    if (initialMedia != null && mounted) {
      debugPrint('[AppRoot] handling initial media...');
      // 冷启动时用 addPostFrameCallback，确保 Provider 树已经挂好
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleSharedMedia(initialMedia!);
      });
    }

    // 2. App 已在前台/后台，再通过分享唤醒
    _subscription = _shareHandler.sharedMediaStream.listen(
          (SharedMedia media) async {
        debugPrint('[AppRoot] sharedMediaStream event: $media');
        if (!mounted) return;
        await _handleSharedMedia(media);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('[AppRoot] sharedMediaStream error: $error\n$stack');
      },
    );

    debugPrint('[AppRoot] initPlatformState done');
  }

  /// 这里只做一件事：把分享过来的路径写到 ImagePickerProvider 里，不做导航。
  Future<void> _handleSharedMedia(SharedMedia media) async {
    final paths = _imageShareService.extractPaths(media);
    debugPrint('[AppRoot] _handleSharedMedia paths: $paths');

    if (paths.isEmpty) {
      return;
    }

    try {
      final imagePicker = context.read<ImagePickerProvider>();
      imagePicker.setSelected(paths);
      debugPrint('[AppRoot] ImagePickerProvider.setSelected called');
    } catch (e, stack) {
      debugPrint('[AppRoot] setSelected error: $e\n$stack');
    }

    // 导航留给已有的 Fluro / IndexPage 体系去处理，
    // 避免在这里和 Fluro / Forui 的 Navigator 交叉导致各种奇怪问题。
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
            ? const MainPage()
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
