import 'package:hive/hive.dart';

class StorageService {
  static const String _boxName = 'authBox';
  static const String _tokenKey = 'auth_token';

  // 获取盒子的实例
  final Box _box = Hive.box(_boxName);

  // 保存 token
  Future<void> saveToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  // 获取 token
  String? getToken() {
    return _box.get(_tokenKey);
  }

  // 清除 token
  Future<void> clearToken() async {
    await _box.delete(_tokenKey);
  }
}
