import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watermarker_v2/providers/user_provider.dart';
import 'package:watermarker_v2/providers/work_order_provider.dart';

import 'package:watermarker_v2/providers/app_config_provider.dart';
import 'package:watermarker_v2/providers/image_picker_provider.dart';
import 'package:watermarker_v2/pages/root/app_root.dart';

Future<void> main() async {
  // 启动 Flutter
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: const AppRoot(),
    ),
  );
}
