import 'package:flutter/material.dart';

const primaryColor = Color(0xFF24292E); // GitHub 头部黑
const accentColor = Color(0xFF0366D6); // GitHub 链接蓝
const lightGreyColor = Color(0xFFF6F8FA); // 浅灰背景

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: primaryColor,
    secondary: accentColor,
    surface: lightGreyColor, // 用于 Card
    surfaceContainer: Colors.grey[200], // 新增的卡片背景色
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Colors.grey.shade900,
    primary: Colors.grey.shade500,
    secondary: Colors.grey.shade400,
    surfaceContainer: Colors.grey.shade800, // 新增的卡片背景色
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
  ),
);
