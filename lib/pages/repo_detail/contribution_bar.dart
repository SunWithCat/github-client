import 'package:flutter/material.dart';

class ContributionBar extends StatelessWidget {
  /// 当前贡献者的贡献数
  final int contributions;

  /// 项目总贡献数（用于计算百分比）
  final int totalContributions;

  /// 进度条高度
  final double height;

  /// 进度条颜色
  final Color? color;

  /// 背景颜色
  final Color? backgroundColor;

  /// 是否显示百分比文字
  final bool showPercentage;

  const ContributionBar({
    super.key,
    required this.contributions,
    required this.totalContributions,
    this.height = 6,
    this.color,
    this.backgroundColor,
    this.showPercentage = true,
  });

  /// 计算贡献百分比 (0.0 - 100.0)
  double get percentage {
    if (totalContributions <= 0) return 0.0;
    return (contributions / totalContributions * 100).clamp(0.0, 100.0);
  }

  /// 计算进度比例 (0.0 - 1.0)
  double get progress {
    if (totalContributions <= 0) return 0.0;
    return (contributions / totalContributions).clamp(0.0, 1.0);
  }

  /// 格式化百分比显示
  String get percentageText {
    if (percentage < 0.1) {
      return '<0.1%';
    } else if (percentage < 1) {
      return '${percentage.toStringAsFixed(1)}%';
    } else {
      return '${percentage.toStringAsFixed(1)}%';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    return Row(
      children: [
        // 进度条
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final progressWidth = maxWidth * progress;

              return Container(
                height: height,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: progressWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 百分比文字
        if (showPercentage) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              percentageText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }
}
