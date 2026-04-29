/// Tina DeskMate — 手機入口
///
/// GetX 初始化 + 主題設定
/// 無需 MaterialApp 路由，主畫面直接啟動

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 強制直向，鎖定螢幕方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 全螢幕沉浸模式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const TinaDeskMateApp());
}

class TinaDeskMateApp extends StatelessWidget {
  const TinaDeskMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tina DeskMate',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFFD700),
          surface: const Color(0xFF16213E),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
