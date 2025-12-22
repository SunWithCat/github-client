import 'package:flutter/material.dart';

class StatItem extends StatelessWidget {
  /// 统计项图标
  final IconData icon;
  
  /// 统计值（已格式化的字符串）
  final String value;
  
  /// 统计项标签
  final String label;
  
  /// 图标颜色
  final Color? iconColor;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  /// 格式化数字，将大数字转换为易读格式
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? theme.iconTheme.color,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
