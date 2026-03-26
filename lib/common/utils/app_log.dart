import 'package:flutter/foundation.dart';

class AppLog {
  const AppLog._();

  static void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('WARN: $message');
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');

      if (error != null) {
        debugPrint('DETAIL: $error');
      }

      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
