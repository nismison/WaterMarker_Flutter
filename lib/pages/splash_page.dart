// lib/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 控制 SplashScreen 文案的控制器，暴露 updateMessage 方法
class SplashController extends ChangeNotifier {
  SplashController({String initialMessage = '正在初始化...'}) : _message = initialMessage;

  String _message;
  String get message => _message;

  /// 在初始化期间更新显示文字
  void updateMessage(String message) {
    if (message == _message) return;
    _message = message;
    notifyListeners();
  }
}

/// 冷启动期间显示的开屏动画页面
class SplashScreen extends StatelessWidget {
  final SplashController controller;

  const SplashScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 可以根据你的 App 风格调整颜色
      backgroundColor: Colors.white,
      body: Align(
        alignment: const Alignment(0, -0.2), // y 轴向上偏移 20%
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;

                    return SizedBox(
                      width: maxWidth, // 与屏幕等宽
                      child: FittedBox(
                        fit: BoxFit.contain, // 保持原始比例
                        child: SizedBox(
                          width: maxWidth,
                          child: Lottie.asset(
                            'assets/animations/splash_loading.json',
                            repeat: true,
                            animate: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  controller.message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
