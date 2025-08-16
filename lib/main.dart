import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghclient/services/storage_service.dart';
import './profile_change.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import './theme/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  // 确保Flutter应用在运行前已经初始化
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  const secureStorage = FlutterSecureStorage();
  
  final String? encryptionKeyString = await secureStorage.read(key: 'hive_encryption_key');

  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
  }

  final keyString = await secureStorage.read(key: 'hive_encryption_key');
  final Uint8List encryptionKey = base64Url.decode(keyString!);

  await Hive.openBox(
    'authBox',
    encryptionCipher: HiveAesCipher(encryptionKey), // 使用 encryptionCipher 参数
  );

  final storageService = StorageService();
  await storageService.init();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close(); // 关闭 Hive Box
    }
  }

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
