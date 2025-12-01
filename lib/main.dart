import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watermarker_v2/providers/fm_config_provider.dart';
import 'package:flutter/services.dart';

import 'package:watermarker_v2/providers/user_provider.dart';
import 'package:watermarker_v2/providers/work_order_provider.dart';
import 'package:watermarker_v2/providers/app_config_provider.dart';
import 'package:watermarker_v2/providers/image_picker_provider.dart';
import 'package:watermarker_v2/pages/root/app_root.dart';

import 'package:watermarker_v2/background/background_jobs.dart';

/// Android headless 模式下的回调必须是顶层函数
/// 加上 @pragma('vm:entry-point') 确保不会被 tree-shaking 干掉
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool timeout = task.timeout;

  if (timeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    // 仍然复用你在 background_jobs.dart 里的业务逻辑
    await handleBackgroundFetch(taskId, isHeadless: true);
  } catch (e, stack) {
    // TODO: 换成你自己的日志
    // debugPrint('[Headless] backgroundFetchHeadlessTask error: $e\n$stack');
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

Future<void> main() async {
  // 启动 Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 注册 Android headless 任务回调
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  // 配置 Android 状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,

      // 底部导航栏背景色：用你 App 的浅色背景
      systemNavigationBarColor: Color(0xFFF3F4F6),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 挂载 Provider，真正的初始化逻辑在 AppRoot 中统一管理
  runApp(
    MultiProvider(
      providers: [
        // App 配置 Provider
        ChangeNotifierProvider<AppConfigProvider>(
          create: (_) => AppConfigProvider(),
        ),
        // 图片选择 Provider
        ChangeNotifierProvider<ImagePickerProvider>(
          create: (_) => ImagePickerProvider(),
        ),
        // 工单列表 Provider
        ChangeNotifierProvider(create: (_) => WorkOrderProvider()),
        // 用户列表 Provider
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<FmConfigProvider>(
          create: (_) => FmConfigProvider(),
        ),
      ],
      child: const AppRoot(),
    ),
  );
}
