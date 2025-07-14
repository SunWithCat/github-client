import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './profile_change.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import './theme/theme_provider.dart';

void main() {
  // 确保Flutter应用在运行前已经初始化
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProfileChange()..init()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileChange = context.watch<ProfileChange>();
    final bool isLoading = profileChange.isLoading;
    final bool isLoggedIn = profileChange.isLoggedIn;

    // 根据当前主题的亮度决定状态栏图标的颜色
    final Brightness statusBarIconBrightness =
        themeProvider.themeData.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GhClient',
        home:
            isLoading
                ? Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15.0),
                        const Text('登陆中'),
                      ],
                    ),
                  ),
                )
                : isLoggedIn
                ? const HomePage()
                : const LoginPage(),
        theme: themeProvider.themeData,
      ),
    );
  }
}
