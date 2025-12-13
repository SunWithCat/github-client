import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';

/// 登录页：使用 ConsumerStatefulWidget
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  StreamSubscription? _sub; // 用于取消监听

  @override
  void initState() {
    super.initState();
    _initUniLinks(); // 初始化时就监听传入的链接
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    final appLinks = AppLinks();
    _sub = appLinks.uriLinkStream.listen(
      // 接收从外部传入的链接
      (Uri? uri) {
        if (uri != null &&
            uri.toString().startsWith(AppConfig.githubCallbackUrl)) {
          _handleAuthCallback(uri); // 如果链接正确，则处理
        }
      },
      onError: (err) {
        // 处理错误
        print('app_links error: $err');
      },
    );
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    final code = uri.queryParameters['code']; // 从回调URL中提取code
    if (code != null) {
      setState(() {
        _isLoading = true;
      });
      // 🔄 使用 ref.read 获取 notifier
      final profileNotifier = ref.read(profileProvider.notifier);
      final navigator = Navigator.of(context);

      try {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: '登陆中，请稍后...',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
        final dio = Dio();

        final response = await dio.post(
          'https://github.com/login/oauth/access_token',
          data: {
            'client_id': AppConfig.githubClientId,
            'client_secret': AppConfig.githubClientSecret,
            'code': code,
          },
          options: Options(headers: {'Accept': 'application/json'}),
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          final accessToken = response.data['access_token'];
          final storage = StorageService();
          await storage.init();
          await storage.saveToken(accessToken);
          if (!mounted) return;
          profileNotifier.login(accessToken);
          navigator.pushReplacementNamed('/');
        }
      } catch (e) {
        print('换取 token 失败： $e');
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: '登录失败，请重试',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Uri get githubAuthUrl {
    // 构建并返回一个用于发起Github的OAuth登录授权的完整Uri对象(URL)
    return Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': AppConfig.githubClientId,
      'scope': 'user repo',
      'redirect_uri': AppConfig.githubCallbackUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(OctIcons.mark_github_16, size: 32),
            const SizedBox(height: 10),
            Text(
              '登录到 GitHub ',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                icon: const Icon(OctIcons.sign_in_16),
                onPressed: () async {
                  // 点击按钮后，启动URL
                  final url = githubAuthUrl;
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    if (!mounted) return;
                    Fluttertoast.showToast(
                      msg: "无法打开链接，请检查网络或浏览器设置！",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                    );
                  }
                },
                label: const Text('Login with GitHub'),
              ),
          ],
        ),
      ),
    );
  }
}
