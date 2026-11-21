import 'package:flutter/material.dart';

const primaryColor = Color(0xFF24292E); // GitHub 头部黑
const accentColor = Color(0xFF0366D6); // GitHub 链接蓝
const lightGreyColor = Color(0xFFF5F7F9); // 浅灰背景

// GitHub Dark 语义色阶
const darkCanvasColor = Color(0xFF0D1117);
const darkSurfaceColor = Color(0xFF161B22);
const darkElevatedSurfaceColor = Color(0xFF21262D);
const darkBorderColor = Color(0xFF30363D);
const darkAccentColor = Color(0xFF1F6FEB);
const darkTextPrimaryColor = Color(0xFFE6EDF3);
const darkTextSecondaryColor = Color(0xFF8B949E);

TextTheme _buildBaseTextTheme(Brightness brightness) {
  final fallback = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  return fallback.copyWith(
    headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
  );
}

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: const Color(0xFFF5F7F9), // GitHub 风格的背景色
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: const Color(0xFFB3D4FC),
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
  textTheme: _buildBaseTextTheme(Brightness.light),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkCanvasColor,
  dividerColor: darkBorderColor,
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade300,
    onPrimary: darkCanvasColor,
    secondary: darkAccentColor,
    onSecondary: Colors.white,
    surface: darkSurfaceColor,
    onSurface: darkTextPrimaryColor,
    onSurfaceVariant: darkTextSecondaryColor,
    surfaceContainer: darkSurfaceColor,
    surfaceContainerHighest: darkElevatedSurfaceColor,
    outlineVariant: darkBorderColor,
    surfaceTint: Colors.transparent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkCanvasColor,
    foregroundColor: darkTextPrimaryColor,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: darkSurfaceColor,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.35),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: darkBorderColor, width: 1.0),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: _buildBaseTextTheme(Brightness.dark),
);
