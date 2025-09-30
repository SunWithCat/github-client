import 'package:flutter/material.dart';
import 'package:ghclient/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = ThemeMode.system == ThemeMode.light ? lightMode : darkMode;

  ThemeData get themeData => _themeData;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
