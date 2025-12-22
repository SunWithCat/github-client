import 'package:flutter/material.dart';

class IssueLabel extends StatelessWidget {
  /// 标签名称
  final String name;
  
  /// 标签颜色（GitHub API 返回的 hex 格式，不带 # 前缀）
  final String color;

  const IssueLabel({
    super.key,
    required this.name,
    required this.color,
  });

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
    final r = backgroundColor.r;
    final g = backgroundColor.g;
    final b = backgroundColor.b;
    
    // 计算相对亮度 (使用 sRGB 亮度公式)
    final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
    
    // 亮度阈值：0.5 以上为浅色背景
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = hexToColor(color);
    final textColor = getContrastColor(backgroundColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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
