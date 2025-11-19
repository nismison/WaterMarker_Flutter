import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'providers/image_picker_provider.dart';

// 全局 RouteObserver，用于监听页面返回事件（RouteAware）
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  AppRouter.setupRouter();
  runApp(const WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = FThemes.zinc.light;

    // 自定义主题样式
    final theme = baseTheme.copyWith(
      // tielGroupItem 增加边距
      tileGroupStyle: baseTheme.tileGroupStyle
          .copyWith(
            tileStyle: baseTheme.tileGroupStyle.tileStyle
                .copyWith(
                  decoration: baseTheme.tileGroupStyle.tileStyle.decoration,
                  contentStyle: baseTheme.tileGroupStyle.tileStyle.contentStyle
                      .copyWith(
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                      )
                      .call,
                )
                .call,
          )
          .call,

      // modalSheet 添加模糊
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

      // scaffold 添加边距
      scaffoldStyle: FScaffoldStyle(
        systemOverlayStyle: SystemUiOverlayStyle(),
        backgroundColor: Colors.white,
        sidebarBackgroundColor: Colors.white,
        childPadding: EdgeInsetsGeometry.zero,
        footerDecoration: BoxDecoration(),
      ).call,

      // header 添加边距
      headerStyles: baseTheme.headerStyles
          .copyWith(
            rootStyle: baseTheme.headerStyles.rootStyle
                .copyWith(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                )
                .call,
          )
          .call,

      dialogRouteStyle: baseTheme.dialogRouteStyle.copyWith(
        barrierFilter: (animation) => ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: animation * 5, sigmaY: animation * 5),
          inner: ColorFilter.mode(baseTheme.colors.barrier, BlendMode.srcOver),
        ),
      ).call
    );

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ImagePickerProvider())],
      child: MaterialApp(
        title: '图片选择 Demo',
        theme: theme.toApproximateMaterialTheme(),
        builder: (_, child) => FAnimatedTheme(data: theme, child: child!),
        onGenerateRoute: AppRouter.router.generator,
        initialRoute: '/',
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
