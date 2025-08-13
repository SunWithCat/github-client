import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ghclient/profile_change.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import 'dart:async'; // 引入异步库
import 'package:uni_links/uni_links.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    _sub = uriLinkStream.listen(
      // 接收从外部传入的链接
      (Uri? uri) {
        if (uri != null &&
            uri.toString().startsWith(AppConfig.githubCallbackUrl)) {
          _handleAuthCallback(uri); // 如果链接正确，则处理
        }
      },
      onError: (err) {
        // 处理错误
        print('uni_links error: $err');
      },
    );
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    final code = uri.queryParameters['code']; // 从回调URL中提取code
    if (code != null) {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登陆中，请稍后...')));
        final dio = Dio(); // 创建一个Dio实例，用于发起网络请求

        // 异步发送POST请求到GitHub，用`code`换取`access_token`
        final response = await dio.post(
          'https://github.com/login/oauth/access_token',
          data: {
            'client_id': AppConfig.githubClientId,
            'client_secret': AppConfig.githubClientSecret,
            'code': code,
          },
          options: Options(
            headers: {'Accept': 'application/json'},
          ), // 返回的数据打包成JSON格式
        );
        if (response.statusCode == 200) {
          final accessToken = response.data['access_token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('github_access_token', accessToken);
          Provider.of<ProfileChange>(context, listen: false).login(accessToken);
        }
      } catch (e) {
        print('换取 token 失败： $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登录失败，请重试')));
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
            const FaIcon(FontAwesomeIcons.github, size: 32),
            const SizedBox(height: 10),
            const Text(
              '登录到 GitHub ',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              onPressed: () async {
                // 点击按钮后，启动URL
                final url = githubAuthUrl;
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  // 若无法启动，提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('无法打开链接，请检查网络或浏览器设置！')),
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
