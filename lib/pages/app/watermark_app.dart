// lib/pages/watermark_app.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'package:watermarker_v2/router.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = FThemes.zinc.light;

    final theme = baseTheme.copyWith(
      tileGroupStyle: baseTheme.tileGroupStyle
          .copyWith(
            decoration: baseTheme.tileGroupStyle.decoration.copyWith(
              border: Border.all(width: 0, color: Colors.transparent),
              borderRadius: BorderRadius.zero,
            ),
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
