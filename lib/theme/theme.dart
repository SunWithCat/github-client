import 'package:flutter/material.dart';

const primaryColor = Color(0xFF24292E); // GitHub 头部黑
const accentColor = Color(0xFF0366D6); // GitHub 链接蓝
const lightGreyColor = Color(0xFFF5F7F9); // 浅灰背景

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: const Color(0xFFF5F7F9), // GitHub 风格的背景色
  colorScheme: ColorScheme.light(
    background: const Color(0xFFF5F7F9),
    primary: primaryColor,
    secondary: accentColor,
    surface: Colors.white,
    surfaceContainer: Colors.white,
    surfaceTint: Colors.white, // 防止 Material 3 的色调融合
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 3.0, // 增加阴影
    shadowColor: Colors.black.withValues(alpha: 0.08), // 更柔和的阴影
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200, width: 1.0),
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212), // 匹配 colorScheme 的背景色
  colorScheme: ColorScheme.dark(
    background: const Color(0xFF121212), // 更深的背景色
    primary: Colors.grey.shade400,
    secondary: Colors.grey.shade300,
    surface: const Color(0xFF1E1E1E), // 较浅的表面颜色
    surfaceContainer: const Color(0xFF1E1E1E),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF2C2C2C), // 使用明显更浅的灰色
    elevation: 4.0, // 进一步增加阴影深度
    shadowColor: Colors.black.withValues(alpha: 0.5), // 增加阴影不透明度
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
  ),
);
