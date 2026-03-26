import 'dart:convert';

import 'package:ghclient/common/utils/app_log.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/models/repo.dart';
import 'package:hive/hive.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static const String _boxName = 'authBox';
  static const String _tokenKey = 'auth_token';

  static const String _userKey = 'user_info';
  static const String _reposKey = 'user_repos';
  static const String _starredKey = 'user_starred';
  static const String _readmeKey = 'user_readme';

  // 获取盒子的实例
  late Box _box;
  bool _initialized = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // 初始化方法
  Future<void> init() async {
    if (!_initialized) {
      // 不需要再次打开Box，因为在main.dart中已经使用加密方式打开了
      // 直接获取已打开的Box实例
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
        _initialized = true;
      } else {
        // 如果Box未打开，这可能是一个错误，因为main.dart应该已经打开了Box
        AppLog.w('authBox 未在 main.dart 中打开');
        // 这里不应该尝试重新打开Box，因为缺少加密参数
        // 应该依赖main.dart中的初始化
      }
    }
  }

  // 保存 token
  Future<void> saveToken(String token) async {
    if (!_initialized) await init();
    await _box.put(_tokenKey, token);
  }

  // 获取 token
  Future<String?> getToken() async {
    if (!_initialized) await init();
    return _box.get(_tokenKey);
  }

  // 保存用户信息
  Future<void> saveUser(User user) async {
    if (!_initialized) await init();
    await _box.put(_userKey, jsonEncode(user.toJson()));
  }

  // 获取用户信息
  Future<User?> getUser() async {
    if (!_initialized) await init();
    final String? data = _box.get(_userKey);
    if (data == null) return null;
    try {
      return User.fromJson(jsonDecode(data));
    } catch (e, s) {
      AppLog.e('读取缓存 User 失败😅', e, s);
      return null;
    }
  }

  // 保存仓库列表
  Future<void> saveRepos(List<Repo> repos) async {
    if (!_initialized) await init();
    final String data = jsonEncode(repos.map((e) => e.toJson()).toList());
    await _box.put(_reposKey, data);
  }

  // 获取仓库列表
  Future<List<Repo>> getRepos() async {
    if (!_initialized) await init();
    final String? data = _box.get(_reposKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Repo.fromJson(e)).toList();
    } catch (e, s) {
      AppLog.e('读取缓存 Repos 失败😅', e, s);
      return [];
    }
  }

  // ⭐ 保存 Star 仓库列表
  Future<void> saveStarredRepos(List<Repo> repos) async {
    if (!_initialized) await init();
    final String data = jsonEncode(repos.map((e) => e.toJson()).toList());
    await _box.put(_starredKey, data);
  }

  // 🌟 获取 Star 仓库列表
  Future<List<Repo>> getStarredRepos() async {
    if (!_initialized) await init();
    final String? data = _box.get(_starredKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Repo.fromJson(e)).toList();
    } catch (e, s) {
      AppLog.e('读取缓存 Starred Repos 失败😅', e, s);
      return [];
    }
  }

  // 📝 保存 README
  Future<void> saveReadme(String content) async {
    if (!_initialized) await init();
    await _box.put(_readmeKey, content);
  }

  // 📜 获取 README
  Future<String?> getReadme() async {
    if (!_initialized) await init();
    return _box.get(_readmeKey);
  }

  // 清除 token
  Future<void> clearToken() async {
    if (!_initialized) await init();
    await _box.delete(_tokenKey);
    await _box.delete(_userKey);
    await _box.delete(_reposKey);
    await _box.delete(_starredKey);
    await _box.delete(_readmeKey);
    // 移除 _box.close() 调用，保持 Box 在应用生命周期内打开
    // Box 应该只在应用退出时关闭
  }
}
