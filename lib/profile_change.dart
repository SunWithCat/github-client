import 'package:flutter/material.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:ghclient/services/storage_service.dart';
import 'models/my_user_model.dart'; // 用户模型
import 'models/repo.dart'; // 仓库模型

class Profile {
  String? token;
  User? user;
  List<Repo> repos = [];
  List<Repo> starredRepos = [];
  String? profileReadme; // README
  int starredReposCurrentPage = 1;
  int reposCurrentPage = 1;
  bool starredReposHasMore = true;
  bool reposHasMore = true;
  Profile({this.token, this.user});
}

class ProfileChange extends ChangeNotifier {
  Profile _profile = Profile();
  bool _isLoading = true; // 加载状态
  Profile get profile => _profile;
  bool get isLoggedIn => _profile.token != null;
  bool get isLoading => _isLoading;

  final GithubService _githubService = GithubService();
  final StorageService _storageService = StorageService();

  // 登录方法
  Future<void> login(String token) async {
    _profile.token = token;
    _isLoading = true;
    notifyListeners();
    try {
      // 获取用户信息
      final user = await _githubService.getUser(token);
      _profile.user = user;
      // 并行获取仓库、星标仓库、README
      final results = await Future.wait([
        _githubService.getRepos(token),
        _githubService.getStarredRepos(token, page: 1),
        _githubService.getProfileReadme(user.login, token),
      ]);
      // 赋值
      _profile.repos = results[0] as List<Repo>;
      _profile.starredRepos = results[1] as List<Repo>;
      _profile.profileReadme = results[2] as String?;
    } catch (e) {
      print('登录或获取用户信息失败：$e');
      logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 退出登录
  void logout() async {
    _profile = Profile(); // 重置 Profile 对象
    await _storageService.clearToken();
    notifyListeners();
  }

  // 初始化
  Future<void> init() async {
    final String? accessToken = await _storageService.getToken();
    if (accessToken != null) {
      await login(accessToken);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 加载更多星标仓库
  Future<List<Repo>> loadMoreStarredRepos() async {
    if (_profile.token == null || !_profile.starredReposHasMore) {
      return [];
    }
    try {
      final newRepos = await _githubService.getStarredRepos(
        _profile.token!,
        page: _profile.starredReposCurrentPage + 1,
      );
      if (newRepos.isEmpty) {
        _profile.starredReposHasMore = false;
      } else {
        _profile.starredReposCurrentPage++;
        _profile.starredRepos.addAll(newRepos);
        notifyListeners();
      }
      return newRepos;
    } catch (e) {
      print('加载更多星标仓库失败：$e');
      return [];
    }
  }

  // 加载更多仓库
  Future<List<Repo>> loadMoreRepos() async {
    if (_profile.token == null || !_profile.reposHasMore) {
      return [];
    }
    try {
      final newRepos = await _githubService.getRepos(
        _profile.token!,
        page: _profile.reposCurrentPage + 1,
      );
      if (newRepos.isEmpty) {
        _profile.reposHasMore = false;
      } else {
        _profile.reposCurrentPage++;
        _profile.repos.addAll(newRepos);
        notifyListeners();
      }
      return newRepos;
    } catch (e) {
      print('加载更多仓库失败：$e');
      return [];
    }
  }
}
