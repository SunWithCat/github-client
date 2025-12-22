import 'package:flutter/material.dart';
import 'package:ghclient/common/utils/date_formatter.dart';

class DateSeparator extends StatelessWidget {
  /// 分隔日期
  final DateTime date;

  const DateSeparator({
    super.key,
    required this.date,
  });

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧分隔线
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          // 日期标签
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                relativeDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 右侧分隔线
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
