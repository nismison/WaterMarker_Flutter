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
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/splash_loading.json',
                    repeat: true,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.message,
                  style: const TextStyle(
                    color: Colors.white,
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
