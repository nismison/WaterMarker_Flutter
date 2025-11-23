import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:water_marker_test2/services/image_sync_service.dart';
import 'package:water_marker_test2/utils/storage_util.dart';

import 'providers/app_config_provider.dart';
import 'providers/image_picker_provider.dart';
import 'api/http_client.dart';
import 'router.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  // 启动 Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 路由初始化
  AppRouter.setupRouter();

  // 设置后端 BaseUrl
  HttpClient.setBaseUrl("https://api.zytsy.icu");

  // 加载 AppConfig
  final appConfigProvider = AppConfigProvider();
  await loadAppConfig(appConfigProvider);

  // 启动 App
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>(
          create: (_) => appConfigProvider,
        ),
        ChangeNotifierProvider<ImagePickerProvider>(
          create: (_) => ImagePickerProvider(),
        ),
      ],
      child: const WatermarkApp(),
    ),
  );

  /// UI 构建完毕后再同步所有图片
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // 同步所有图片
    startScanImages();
  });
}

Future<void> startScanImages() async {
  final hasAll = await StorageUtil.hasAllFilesAccess();
  if (hasAll) {
    /// 测试模式：只压接口，不动 SQLite
    /// 正常模式：带本地索引的增量同步
    final isTest = false;

    final prodService = ImageSyncService(isTest: isTest);
    await prodService.syncAllImages();
  }
}

Future<void> loadAppConfig(AppConfigProvider appConfigProvider) async {
  // 初始化 AppConfigProvider 并加载本地缓存
  await appConfigProvider.loadLocalConfig();
  // 刷新 AppConfigProvider
  try {
    await appConfigProvider.refreshConfig();
  } catch (e) {
    debugPrint("AppConfig: 远端配置刷新失败，已回退至本地缓存: $e");
  }
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = FThemes.zinc.light;

    final theme = baseTheme.copyWith(
      tileGroupStyle: baseTheme.tileGroupStyle
          .copyWith(
            tileStyle: baseTheme.tileGroupStyle.tileStyle
                .copyWith(
                  decoration: baseTheme.tileGroupStyle.tileStyle.decoration,
                  contentStyle: baseTheme.tileGroupStyle.tileStyle.contentStyle
                      .copyWith(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                      )
                      .call,
                )
                .call,
          )
          .call,
      modalSheetStyle: baseTheme.modalSheetStyle
          .copyWith(
            barrierFilter: (animation) => ImageFilter.compose(
              outer: ImageFilter.blur(
                sigmaX: animation * 5,
                sigmaY: animation * 5,
              ),
              inner: ColorFilter.mode(
                baseTheme.colors.barrier,
                BlendMode.srcOver,
              ),
            ),
          )
          .call,
      scaffoldStyle: FScaffoldStyle(
        systemOverlayStyle: const SystemUiOverlayStyle(),
        backgroundColor: Colors.white,
        sidebarBackgroundColor: Colors.white,
        childPadding: EdgeInsetsGeometry.zero,
        footerDecoration: const BoxDecoration(),
      ).call,
      headerStyles: baseTheme.headerStyles
          .copyWith(
            rootStyle: baseTheme.headerStyles.rootStyle
                .copyWith(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 15,
                  ),
                )
                .call,
          )
          .call,
      dialogRouteStyle: baseTheme.dialogRouteStyle
          .copyWith(
            barrierFilter: (animation) => ImageFilter.compose(
              outer: ImageFilter.blur(
                sigmaX: animation * 5,
                sigmaY: animation * 5,
              ),
              inner: ColorFilter.mode(
                baseTheme.colors.barrier,
                BlendMode.srcOver,
              ),
            ),
          )
          .call,
    );

    return MaterialApp(
      title: '图片选择 Demo',
      theme: theme.toApproximateMaterialTheme(),
      builder: (_, child) => FAnimatedTheme(data: theme, child: child!),
      onGenerateRoute: AppRouter.router.generator,
      initialRoute: '/',
      navigatorObservers: [routeObserver],
    );
  }
}
