class DateFormatter {
  /// 格式化 ISO 8601 日期字符串为完整的本地时间格式
  /// 输出格式: "YYYY-MM-DD HH:mm:ss"
  static String format(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.year}-${_pad(date.month)}-${_pad(date.day)} '
          '${_pad(date.hour)}:${_pad(date.minute)}:${_pad(date.second)}';
    } catch (e) {
      return isoDate;
    }
  }

  /// 格式化 ISO 8601 日期字符串为相对时间
  /// 例如: "刚刚", "5分钟前", "2小时前", "3天前", "1个月前", "2年前"
  static String relative(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) {
        // 未来时间，返回格式化的日期
        return format(isoDate);
      }

      if (difference.inSeconds < 60) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months个月前';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years年前';
      }
    } catch (e) {
      return isoDate;
    }
  }

  /// 格式化 ISO 8601 日期字符串为仅日期格式
  /// 输出格式: "YYYY-MM-DD"
  static String dateOnly(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
    } catch (e) {
      return isoDate;
    }
  }

  /// 将数字填充为两位数字符串
  static String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }
}
