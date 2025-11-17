import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'providers/image_picker_provider.dart';

void main() {
  AppRouter.setupRouter();
  runApp(const WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImagePickerProvider()),
      ],
      child: MaterialApp(
        title: '图片选择 Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        onGenerateRoute: AppRouter.router.generator,
        initialRoute: '/',
      ),
    );
  }
}
