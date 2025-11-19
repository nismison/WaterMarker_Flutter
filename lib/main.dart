import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import 'providers/app_config_provider.dart';
import 'providers/image_picker_provider.dart';
import 'utils/http/http_client.dart';
import 'router.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppRouter.setupRouter();

  // 设置后端 BaseUrl
  HttpClient.setBaseUrl("https://api.zytsy.icu");

  // 初始化 AppConfigProvider 并加载本地缓存
  final appConfigProvider = AppConfigProvider();
  await appConfigProvider.loadLocalConfig();

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

  /// UI 构建完毕后再请求远端配置
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await appConfigProvider.refreshConfig();
    } catch (e) {
      debugPrint("AppConfig: 远端配置刷新失败，已回退至本地缓存: $e");
    }
  });
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
