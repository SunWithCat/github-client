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

  final GithubService _githubService = GithubService.instance;
  final StorageService _storageService = StorageService();

  Future<void> init() async {
    final String? accessToken = await _storageService.getToken();
    if (accessToken != null) {
      _profile.token = accessToken;
      final bool hasCache = await _initFromCache();

      if (hasCache) {
        _isLoading = false;
        notifyListeners();

        print('🚀 命中缓存，进入静默刷新模式');
        silentLogin(accessToken);
      } else {
        // 无缓存，走正常流程
        print('🐢 无缓存，进入常规登录模式');
        await login(accessToken);
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _initFromCache() async {
    try {
      final user = await _storageService.getUser();
      if (user == null) return false;

      final repos = await _storageService.getRepos();
      final starred = await _storageService.getStarredRepos();
      final readme = await _storageService.getReadme();

      _profile.user = user;
      _profile.repos = repos;
      _profile.starredRepos = starred;
      _profile.profileReadme = readme;

      return true;
    } catch (e) {
      print('读取缓存失败：$e');
      return false;
    }
  }

  // 保存数据到缓存
  Future<void> _saveToCache() async {
    if (_profile.user != null) {
      await _storageService.saveUser(_profile.user!);
    }
    await _storageService.saveRepos(_profile.repos);
    await _storageService.saveStarredRepos(_profile.starredRepos);
    if (_profile.profileReadme != null) {
      await _storageService.saveReadme(_profile.profileReadme!);
    }
  }

  // 静默登录（后台刷新）
  Future<void> silentLogin(String token) async {
    try {
      await _performLoginLogic(token);
      print('静默刷新成功');
    } catch (e) {
      print('静默刷新失败：$e');
      // 不需要退出
    }
  }

  // 登录方法
  Future<void> login(String token) async {
    _profile.token = token;
    _isLoading = true;
    notifyListeners();
    try {
      await _performLoginLogic(token);
    } catch (e) {
      print('登录或获取用户信息失败：$e');
      logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 提取公共的登录
  Future<void> _performLoginLogic(String token) async {
    // 获取用户信息
    final (user, error) = await _githubService.getUser(token);
    if (error != null) {
      throw Exception(error);
    }
    // ✨ 智能更新：只在关键数据变化时才更新 User，避免不必要的重建
    if (_profile.user == null ||
        _profile.user!.avatarUrl != user!.avatarUrl ||
        _profile.user!.name != user.name ||
        _profile.user!.bio != user.bio ||
        _profile.user!.followers != user.followers ||
        _profile.user!.following != user.following) {
      _profile.user = user;
    }

    final results = await Future.wait([
      _githubService.getRepos(token),
      _githubService.getStarredRepos(token, page: 1),
      _githubService.getProfileReadme(user!.login, token),
    ]);

    final reposResult = results[0] as ApiResult<List<Repo>>;
    final starredResult = results[1] as ApiResult<List<Repo>>;
    final readmeResult = results[2] as ApiResult<String?>;

    if (reposResult.$2 != null) print('Repos Error: ${reposResult.$2}');
    if (starredResult.$2 != null) print('Starred Error: ${starredResult.$2}');
    if (readmeResult.$2 != null) print('Readme Error: ${readmeResult.$2}');

    if (reposResult.$1 != null) {
      _profile.repos = reposResult.$1!;
    }

    if (starredResult.$1 != null) {
      _profile.starredRepos = starredResult.$1!;
    }
    if (readmeResult.$1 != null) {
      _profile.profileReadme = readmeResult.$1;
    }

    // 🎉 获取成功后，更新缓存
    await _saveToCache();
    notifyListeners(); // 刷新 UI
  }

  // 退出登录
  void logout() async {
    _profile = Profile(); // 重置 Profile 对象
    await _storageService.clearToken();
    notifyListeners();
  }

  // 加载更多星标仓库
  Future<List<Repo>> loadMoreStarredRepos() async {
    if (_profile.token == null || !_profile.starredReposHasMore) {
      return [];
    }
    try {
      final (newRepos, error) = await _githubService.getStarredRepos(
        _profile.token!,
        page: _profile.starredReposCurrentPage + 1,
      );

      if (error != null) {
        print('加载更多星标仓库失败：$error');
        return [];
      }

      if (newRepos == null || newRepos.isEmpty) {
        _profile.starredReposHasMore = false;
      } else {
        _profile.starredReposCurrentPage++;
        _profile.starredRepos.addAll(newRepos);
        notifyListeners();
      }
      return newRepos ?? [];
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
      final (newRepos, error) = await _githubService.getRepos(
        _profile.token!,
        page: _profile.reposCurrentPage + 1,
      );

      if (error != null) {
        print('加载更多仓库失败：$error');
        return [];
      }

      if (newRepos == null || newRepos.isEmpty) {
        _profile.reposHasMore = false;
      } else {
        _profile.reposCurrentPage++;
        _profile.repos.addAll(newRepos);
        notifyListeners();
      }
      return newRepos ?? [];
    } catch (e) {
      print('加载更多仓库失败：$e');
      return [];
    }
  }
}
