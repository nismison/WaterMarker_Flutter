import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'pages/image_picker_page.dart';
import 'pages/select_images_page.dart';

class AppRouter {
  static final FluroRouter router = FluroRouter();

  static void setupRouter() {
    // 主界面
    router.define(
      '/',
      handler: Handler(handlerFunc: (_, __) => const ImagePickerPage()),
    );

    // 选择图片页面
    router.define(
      '/select_images',
      handler: Handler(handlerFunc: (_, params) {
        final pre = params['preSelected']?.first ?? '';
        return SelectImagesPage(
          preSelectedPaths: pre.isNotEmpty ? pre.split(',') : [],
        );
      }),
    );

    // 404 fallback
    router.notFoundHandler = Handler(
      handlerFunc: (_, __) => const Scaffold(
        body: Center(child: Text('页面不存在')),
      ),
    );
  }

  static Future navigateTo(
      BuildContext context,
      String path, {
        Map<String, dynamic>? params,
        bool replace = false,
        bool clearStack = false,
      }) {
    final query = params != null ? '?${Uri(queryParameters: params).query}' : '';
    return router.navigateTo(
      context,
      '$path$query',
      replace: replace,
      clearStack: clearStack,
      transition: TransitionType.inFromRight,
    );
  }
}
