import 'package:flutter/material.dart';
import 'package:ghclient/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'models/my_user_model.dart'; // 用户模型
import 'models/repo.dart'; // 仓库模型

class Profile {
  String? token;
  User? user;
  List<Repo> repos = [];
  List<Repo> starredRepos = [];
  String? profileReadme; // README
  Profile({this.token, this.user});
}

class ProfileChange extends ChangeNotifier {
  Profile _profile = Profile();
  bool _isLoading = true; // 加载状态
  Profile get profile => _profile;
  bool get isLoggedIn => _profile.token != null;
  bool get isLoading => _isLoading;

  // 登录方法
  Future<void> login(String token) async {
    _profile.token = token;
    try {
      final dio = Dio();
      // 配置请求头，带上token
      dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await dio.get('https://api.github.com/user');
      if (response.statusCode == 200) {
        _profile.user = User.fromJson(response.data);
        // 获取仓库列表
        final reposResponse = await dio.get(
          'https://api.github.com/users/${_profile.user!.login}/repos',
        );
        if (reposResponse.statusCode == 200) {
          _profile.repos =
              (reposResponse.data as List)
                  .map((e) => Repo.fromJson(e))
                  .toList();
        }
        // 获取星标仓库
        try {
          final starredRepoResponse = await dio.get(
            'https://api.github.com/user/starred',
          );
          if (starredRepoResponse.statusCode == 200) {
            _profile.starredRepos =
                (starredRepoResponse.data as List)
                    .map((e) => Repo.fromJson(e))
                    .toList();
          }
        } catch (e) {
          print('获取星标仓库失败:$e');
        }
        // 获取个人主页
        try {
          final readmeResponse = await dio.get(
            'https://api.github.com/repos/${_profile.user!.login}/${_profile.user!.login}/readme',
            options: Options(
              headers: {'Accept': 'application/vnd.github.raw+json'},
              responseType: ResponseType.plain, // 纯文本不解析
            ),
          );
          if (readmeResponse.statusCode == 200) {
            _profile.profileReadme = readmeResponse.data;
          }
        } catch (e) {
          print('获取失败：$e');
          _profile.profileReadme = null;
        }
      }
    } catch (e) {
      print('获取用户信息失败：$e');
      logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 退出登录
  void logout() async {
    _profile = Profile(); // 重置 Profile 对象
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('github_access_token');
    final storage = StorageService();
    storage.clearToken();
    notifyListeners();
  }

  // 初始化
  Future<void> init() async {
    // final prefs = await SharedPreferences.getInstance();
    // final String? accessToken = prefs.getString('github_access_token');
    final storage = StorageService();
    final String? accessToken = await storage.getToken();
    if (accessToken != null) {
      await login(accessToken);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }
}
