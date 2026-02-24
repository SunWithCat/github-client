import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ToastType { success, error, info, warning }

class ToastUtils {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    // Define colors and icons based on type
    final (Color bgColor, Color fgColor, IconData icon) = switch (type) {
      ToastType.success => (
        const Color(0xFF2EA043), // GitHub Green
        Colors.white,
        OctIcons.check_circle_fill_16,
      ),
      ToastType.error => (
        const Color(0xFFDA3633), // GitHub Red
        Colors.white,
        OctIcons.x_circle_fill_16,
      ),
      ToastType.warning => (
        const Color(0xFFD29922), // GitHub Yellow
        Colors.white,
        OctIcons.alert_fill_16,
      ),
      ToastType.info => (
        const Color(0xFF0969DA), // GitHub Blue
        Colors.white,
        OctIcons.info_16,
      ),
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: EdgeInsets.zero,
        content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    theme.brightness == Brightness.dark
                        ? const Color(0xFF24292E) // GitHub暗色面板标准色
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 干净简约，只保留纯粹的 Icon
                  Icon(icon, size: 20, color: bgColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500, // 减弱字重，更显清爽
                        height: 1.4,
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.95)
                                : Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onAction();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // 比较精致的微圆角
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            )
            // 简单的淡入和轻微上滑
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutQuart,
            ),
      ),
    );
  }
}
