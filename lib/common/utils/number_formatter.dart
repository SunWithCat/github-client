abstract final class NumberFormatter {
  // 统一数量为 k / M
  static String formatNumber(int count) {
    if (count < 1000) {
      return count.toString();
    }
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}