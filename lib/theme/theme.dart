import 'package:flutter/material.dart';

const lightCanvasColor = Color(0xFFF6F8FA);
const lightSurfaceColor = Color(0xFFFFFFFF);
const lightContainerSurfaceColor = Color(0xFFF2F5F8);
const lightHighSurfaceColor = Color(0xFFEEF1F5);
const lightElevatedSurfaceColor = Color(0xFFEAEEF2);
const lightBorderColor = Color(0xFFD0D7DE);
const lightStrongBorderColor = Color(0xFF8C959F);
const lightAccentColor = Color(0xFF0969DA);
const lightAccentContainerColor = Color(0xFFDDF4FF);
const lightTextPrimaryColor = Color(0xFF1F2328);
const lightTextSecondaryColor = Color(0xFF59636E);

const darkCanvasColor = Color(0xFF0D1117);
const darkSurfaceColor = Color(0xFF161B22);
const darkContainerSurfaceColor = Color(0xFF1A2028);
const darkHighSurfaceColor = Color(0xFF1E242C);
const darkElevatedSurfaceColor = Color(0xFF21262D);
const darkBorderColor = Color(0xFF30363D);
const darkStrongBorderColor = Color(0xFF6E7681);
const darkPrimaryColor = Color(0xFF58A6FF); // 前景高亮 / 链接 / 指示条蓝
const darkAccentColor = Color(0xFF1F6FEB); // 实心按钮 / FAB 强调蓝
const darkPrimaryContainerColor = Color(0xFF13233A);
const darkOnPrimaryContainerColor = Color(0xFF79C0FF);
const darkTextPrimaryColor = Color(0xFFE6EDF3);
const darkTextSecondaryColor = Color(0xFF8B949E);

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color open;
  final Color closed;
  final Color merged;
  final Color attention;
  final Color star;
  final Color fork;
  final Color link;
  final Color codeBackground;
  final Color inlineCodeBackground;
  final Color blockquoteBorder;
  final Color blockquoteText;

  const AppSemanticColors({
    required this.open,
    required this.closed,
    required this.merged,
    required this.attention,
    required this.star,
    required this.fork,
    required this.link,
    required this.codeBackground,
    required this.inlineCodeBackground,
    required this.blockquoteBorder,
    required this.blockquoteText,
  });

  static const light = AppSemanticColors(
    open: Color(0xFF1A7F37),
    closed: Color(0xFFCF222E),
    merged: Color(0xFF8250DF),
    attention: Color(0xFF9A6700),
    star: Color(0xFFFFB300),
    fork: Color(0xFF00897B),
    link: lightAccentColor,
    codeBackground: Color(0xFFF6F8FA),
    inlineCodeBackground: Color(0xFFEAECEF),
    blockquoteBorder: lightBorderColor,
    blockquoteText: lightTextSecondaryColor,
  );

  static const dark = AppSemanticColors(
    open: Color(0xFF3FB950),
    closed: Color(0xFFF85149),
    merged: Color(0xFFA371F7),
    attention: Color(0xFFE3B341),
    star: Color(0xFFFFB300),
    fork: Color(0xFF4DB6AC),
    link: darkPrimaryColor,
    codeBackground: Color(0xFF1F242C),
    inlineCodeBackground: Color(0xFF262C36),
    blockquoteBorder: darkBorderColor,
    blockquoteText: darkTextSecondaryColor,
  );

  @override
  AppSemanticColors copyWith({
    Color? open,
    Color? closed,
    Color? merged,
    Color? attention,
    Color? star,
    Color? fork,
    Color? link,
    Color? codeBackground,
    Color? inlineCodeBackground,
    Color? blockquoteBorder,
    Color? blockquoteText,
  }) {
    return AppSemanticColors(
      open: open ?? this.open,
      closed: closed ?? this.closed,
      merged: merged ?? this.merged,
      attention: attention ?? this.attention,
      star: star ?? this.star,
      fork: fork ?? this.fork,
      link: link ?? this.link,
      codeBackground: codeBackground ?? this.codeBackground,
      inlineCodeBackground: inlineCodeBackground ?? this.inlineCodeBackground,
      blockquoteBorder: blockquoteBorder ?? this.blockquoteBorder,
      blockquoteText: blockquoteText ?? this.blockquoteText,
    );
  }

  @override
  AppSemanticColors lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      open: Color.lerp(open, other.open, t)!,
      closed: Color.lerp(closed, other.closed, t)!,
      merged: Color.lerp(merged, other.merged, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      star: Color.lerp(star, other.star, t)!,
      fork: Color.lerp(fork, other.fork, t)!,
      link: Color.lerp(link, other.link, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      inlineCodeBackground: Color.lerp(
        inlineCodeBackground,
        other.inlineCodeBackground,
        t,
      )!,
      blockquoteBorder: Color.lerp(
        blockquoteBorder,
        other.blockquoteBorder,
        t,
      )!,
      blockquoteText: Color.lerp(blockquoteText, other.blockquoteText, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSemanticColors &&
        other.open == open &&
        other.closed == closed &&
        other.merged == merged &&
        other.attention == attention &&
        other.star == star &&
        other.fork == fork &&
        other.link == link &&
        other.codeBackground == codeBackground &&
        other.inlineCodeBackground == inlineCodeBackground &&
        other.blockquoteBorder == blockquoteBorder &&
        other.blockquoteText == blockquoteText;
  }

  @override
  int get hashCode => Object.hash(
    open,
    closed,
    merged,
    attention,
    star,
    fork,
    link,
    codeBackground,
    inlineCodeBackground,
    blockquoteBorder,
    blockquoteText,
  );
}

extension AppThemeSemanticX on ThemeData {
  AppSemanticColors get semanticColors =>
      extension<AppSemanticColors>() ??
      (brightness == Brightness.dark
          ? AppSemanticColors.dark
          : AppSemanticColors.light);
}

TextTheme _buildBaseTextTheme(Brightness brightness, Color textColor) {
  final fallback = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  return fallback
      .copyWith(
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
      )
      .apply(bodyColor: textColor, displayColor: textColor);
}

SwitchThemeData _buildSwitchTheme(ColorScheme cs) {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.selected)) {
        return cs.onSecondary;
      }
      return cs.onSurfaceVariant;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.selected)) {
        return cs.secondary;
      }
      return cs.surfaceContainerHighest;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent;
      }
      return cs.outline;
    }),
  );
}

SearchBarThemeData _buildSearchBarTheme(
  ColorScheme cs, {
  required bool isDark,
}) {
  return SearchBarThemeData(
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(
      isDark ? cs.surfaceContainerHighest.withValues(alpha: 0.55) : cs.surface,
    ),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    hintStyle: WidgetStatePropertyAll(TextStyle(color: cs.onSurfaceVariant)),
    shape: WidgetStatePropertyAll(
      RoundedSuperellipseBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: cs.outlineVariant, width: 1.0),
      ),
    ),
  );
}

const _lightColorScheme = ColorScheme.light(
  primary: lightAccentColor,
  onPrimary: Colors.white,
  primaryContainer: lightAccentContainerColor,
  onPrimaryContainer: lightAccentColor,
  secondary: lightAccentColor,
  onSecondary: Colors.white,
  secondaryContainer: lightAccentContainerColor,
  onSecondaryContainer: lightAccentColor,
  error: Color(0xFFCF222E),
  onError: Colors.white,
  errorContainer: Color(0xFFFFEBE9),
  onErrorContainer: Color(0xFFCF222E),
  surface: lightSurfaceColor,
  onSurface: lightTextPrimaryColor,
  onSurfaceVariant: lightTextSecondaryColor,
  surfaceContainerLowest: lightSurfaceColor,
  surfaceContainerLow: lightCanvasColor,
  surfaceContainer: lightContainerSurfaceColor,
  surfaceContainerHigh: lightHighSurfaceColor,
  surfaceContainerHighest: lightElevatedSurfaceColor,
  outline: lightStrongBorderColor,
  outlineVariant: lightBorderColor,
  surfaceTint: Colors.transparent,
);

const _darkColorScheme = ColorScheme.dark(
  primary: darkPrimaryColor,
  onPrimary: darkCanvasColor,
  primaryContainer: darkPrimaryContainerColor,
  onPrimaryContainer: darkOnPrimaryContainerColor,
  secondary: darkAccentColor,
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFF1F3A5F),
  onSecondaryContainer: Color(0xFFCAE8FF),
  error: Color(0xFFF85149),
  onError: darkCanvasColor,
  errorContainer: Color(0xFF3D1A1A),
  onErrorContainer: Color(0xFFFFA198),
  surface: darkSurfaceColor,
  onSurface: darkTextPrimaryColor,
  onSurfaceVariant: darkTextSecondaryColor,
  surfaceContainerLowest: darkCanvasColor,
  surfaceContainerLow: darkSurfaceColor,
  surfaceContainer: darkContainerSurfaceColor,
  surfaceContainerHigh: darkHighSurfaceColor,
  surfaceContainerHighest: darkElevatedSurfaceColor,
  outline: darkStrongBorderColor,
  outlineVariant: darkBorderColor,
  surfaceTint: Colors.transparent,
);

final ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: lightAccentColor,
  scaffoldBackgroundColor: lightCanvasColor,
  dividerColor: lightBorderColor,
  colorScheme: _lightColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: lightCanvasColor,
    foregroundColor: lightTextPrimaryColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: lightSurfaceColor,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: lightBorderColor, width: 1.0),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: lightBorderColor,
    thickness: 1,
    space: 1,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: lightSurfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: lightBorderColor),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: lightSurfaceColor,
    surfaceTintColor: Colors.transparent,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: lightSurfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: lightBorderColor),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: lightAccentColor,
      foregroundColor: Colors.white,
    ),
  ),
  searchBarTheme: _buildSearchBarTheme(_lightColorScheme, isDark: false),
  switchTheme: _buildSwitchTheme(_lightColorScheme),
  tabBarTheme: const TabBarThemeData(
    labelColor: lightAccentColor,
    unselectedLabelColor: lightTextSecondaryColor,
    indicatorColor: lightAccentColor,
    dividerColor: Colors.transparent,
  ),
  extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.light],
  textTheme: _buildBaseTextTheme(Brightness.light, lightTextPrimaryColor),
);

final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: darkPrimaryColor,
  scaffoldBackgroundColor: darkCanvasColor,
  dividerColor: darkBorderColor,
  colorScheme: _darkColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkCanvasColor,
    foregroundColor: darkTextPrimaryColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: darkSurfaceColor,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.35),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: darkBorderColor, width: 1.0),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: darkBorderColor,
    thickness: 1,
    space: 1,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: darkBorderColor),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: darkSurfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: darkBorderColor),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: darkAccentColor,
      foregroundColor: Colors.white,
    ),
  ),
  searchBarTheme: _buildSearchBarTheme(_darkColorScheme, isDark: true),
  switchTheme: _buildSwitchTheme(_darkColorScheme),
  tabBarTheme: const TabBarThemeData(
    labelColor: darkPrimaryColor,
    unselectedLabelColor: darkTextSecondaryColor,
    indicatorColor: darkPrimaryColor,
    dividerColor: Colors.transparent,
  ),
  extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.dark],
  textTheme: _buildBaseTextTheme(Brightness.dark, darkTextPrimaryColor),
);
