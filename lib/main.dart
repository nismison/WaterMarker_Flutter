import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watermarker_v2/providers/user_provider.dart';

import 'providers/app_config_provider.dart';
import 'providers/image_picker_provider.dart';
import 'package:watermarker_v2/pages/root/app_root.dart';

Future<void> main() async {
  // 启动 Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 挂载 Provider，真正的初始化逻辑在 AppRoot 中统一管理
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>(
          create: (_) => AppConfigProvider(),
        ),
        ChangeNotifierProvider<ImagePickerProvider>(
          create: (_) => ImagePickerProvider(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AppRoot(),
    ),
  );
}
