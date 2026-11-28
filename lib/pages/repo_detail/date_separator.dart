import 'package:flutter/material.dart';
import 'package:ghclient/common/utils/date_formatter.dart';

class DateSeparator extends StatelessWidget {
  /// 分隔日期
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  /// 获取格式化的日期字符串
  String get formattedDate {
    final isoString = date.toIso8601String();
    return DateFormatter.dateOnly(isoString);
  }

  /// 获取相对日期描述
  String get relativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '昨天';
    } else if (difference < 7) {
      return '$difference 天前';
    } else {
      return formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.outlineVariant;
    final badgeBgColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧分隔线
          Expanded(child: Container(height: 1, color: lineColor)),
          // 日期标签
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lineColor, width: 1),
              ),
              child: Text(
                relativeDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
          // 右侧分隔线
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
