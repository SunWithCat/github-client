import 'package:flutter/material.dart';

/// GitHub 语言颜色映射
Color getLanguageColor(String? language) {
  return switch (language?.toLowerCase()) {
    null => Colors.grey,
    'dart' => const Color(0xFF00B4AB),
    'java' => const Color(0xFFB07219),
    'javascript' => const Color(0xFFF1E05A),
    'typescript' => const Color(0xFF3178C6),
    'html' => const Color(0xFFE34C26),
    'css' => const Color(0xFF563D7C),
    'vue' => const Color(0xFF41B883),
    'c++' => const Color(0xFFF34B7D),
    'c' => const Color(0xFF555555),
    'c#' => const Color(0xFF178600),
    'python' => const Color(0xFF3572A5),
    'php' => const Color(0xFF4F5D95),
    'ruby' => const Color(0xFF701516),
    'go' => const Color(0xFF00ADD8),
    'rust' => const Color(0xFFDEA584),
    'swift' => const Color(0xFFF05138),
    'kotlin' => const Color(0xFFA97BFF),
    'scala' => const Color(0xFFC22D40),
    'shell' => const Color(0xFF89E051),
    'dockerfile' => const Color(0xFF384D54),
    _ => Colors.grey.shade600,
  };
}
