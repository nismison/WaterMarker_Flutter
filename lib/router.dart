import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'pages/image_picker_page.dart';

/**
 * @description 全局路由管理，基于 Fluro 实现
 *
 * 使用方式：
 * 1. 在 main.dart 中调用 AppRouter.setupRouter() 完成初始化
 * 2. 使用 AppRouter.navigateTo(context, '/route_name') 进行跳转
 */
class AppRouter {
  static final FluroRouter router = FluroRouter();

  /// 初始化路由表
  static void setupRouter() {
    router.define(
      '/image_picker',
      handler: Handler(handlerFunc: (_, __) => const ImagePickerPage()),
    );

    /// 404 兜底
    router.notFoundHandler = Handler(
      handlerFunc: (_, __) => const Scaffold(
        body: Center(
          child: Text('页面不存在'),
        ),
      ),
    );
  }

  /// 简化跳转方法
  static Future navigateTo(
      BuildContext context,
      String path, {
        bool replace = false,
        bool clearStack = false,
      }) {
    return router.navigateTo(
      context,
      path,
      replace: replace,
      clearStack: clearStack,
      transition: TransitionType.inFromRight,
    );
  }
}
