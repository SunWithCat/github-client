import 'package:flutter/material.dart';
import 'package:ghclient/theme/theme.dart';

class IssueLabel extends StatelessWidget {
  /// 标签名称
  final String name;

  /// 标签颜色（GitHub API 返回的 hex 格式，不带 # 前缀）
  final String color;

  const IssueLabel({super.key, required this.name, required this.color});

  /// 将 GitHub API 返回的 hex 颜色字符串转换为 Color 对象
  ///
  /// GitHub API 返回的颜色格式为 6 位 hex 字符串（不带 # 前缀）
  /// 例如: "d73a4a" 表示红色
  static Color hexToColor(String hexColor) {
    // 移除可能存在的 # 前缀
    final hex = hexColor.replaceFirst('#', '');

    // 验证 hex 字符串长度
    if (hex.length != 6 && hex.length != 3) {
      return Colors.grey; // 默认颜色
    }

    // 处理 3 位简写格式（如 "fff" -> "ffffff"）
    final fullHex = hex.length == 3
        ? hex.split('').map((c) => '$c$c').join()
        : hex;

    try {
      return Color(int.parse('FF$fullHex', radix: 16));
    } catch (e) {
      return Colors.grey; // 解析失败时返回默认颜色
    }
  }

  // 神奇的计算
  static Color getContrastColor(Color backgroundColor) {
    final whiteContrast = calculateContrastRatio(Colors.white, backgroundColor);
    final darkContrast = calculateContrastRatio(
      lightTextPrimaryColor,
      backgroundColor,
    );
    return whiteContrast >= darkContrast ? Colors.white : lightTextPrimaryColor;
  }

  /// 计算两个颜色之间相对亮度对比度
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final brightest = l1 > l2 ? l1 : l2;
    final darkest = l1 > l2 ? l2 : l1;
    return (brightest + 0.05) / (darkest + 0.05);
  }

  static Color getDarkBorderColor(
    Color baseColor, {
    required Color surfaceColor,
    required Color fallbackBorderColor,
    double borderAlpha = 0.45,
    double minBorderContrast = 1.35,
  }) {
    final candidate = baseColor.withValues(alpha: borderAlpha);
    final blended = Color.alphaBlend(candidate, surfaceColor);
    if (calculateContrastRatio(blended, surfaceColor) < minBorderContrast) {
      return fallbackBorderColor;
    }
    return candidate;
  }

  /// 动态提亮文字颜色
  static Color getDarkTextColor(
    Color baseColor, {
    Color surfaceColor = const Color(0xFF161B22),
    double backgroundAlpha = 0.18,
    double minContrast = 4.5,
  }) {
    final effectiveBackground = Color.alphaBlend(
      baseColor.withValues(alpha: backgroundAlpha),
      surfaceColor,
    );

    final hsl = HSLColor.fromColor(baseColor);
    final initialLightness = hsl.lightness < 0.72 ? 0.75 : hsl.lightness;
    final candidateHsl = hsl.withLightness(initialLightness);
    final candidateColor = candidateHsl.toColor();

    if (calculateContrastRatio(candidateColor, effectiveBackground) >=
        minContrast) {
      return candidateColor;
    }

    var low = initialLightness;
    var high = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      final probeColor = candidateHsl.withLightness(mid).toColor();
      if (calculateContrastRatio(probeColor, effectiveBackground) >=
          minContrast) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return candidateHsl.withLightness(high).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseColor = hexToColor(color);
    final backgroundColor = isDark
        ? baseColor.withValues(alpha: 0.18)
        : baseColor;
    final textColor = isDark
        ? getDarkTextColor(baseColor, surfaceColor: colorScheme.surface)
        : getContrastColor(baseColor);
    final border = isDark
        ? Border.all(
            color: getDarkBorderColor(
              baseColor,
              surfaceColor: colorScheme.surface,
              fallbackBorderColor: colorScheme.outlineVariant,
            ),
            width: 1.0,
          )
        : (calculateContrastRatio(baseColor, colorScheme.surface) < 1.2
              ? Border.all(color: colorScheme.outlineVariant, width: 1.0)
              : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
