import 'package:hive/hive.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static const String _boxName = 'authBox';
  static const String _tokenKey = 'auth_token';

  // 获取盒子的实例
  late Box _box;
  bool _initialized = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // 初始化方法
  Future<void> init() async {
    if(!_initialized) {
      // 不需要再次打开Box，因为在main.dart中已经使用加密方式打开了
      // 直接获取已打开的Box实例
      if(Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
        _initialized = true;
      } else {
        // 如果Box未打开，这可能是一个错误，因为main.dart应该已经打开了Box
        print('警告: authBox未在main.dart中打开');
        // 这里不应该尝试重新打开Box，因为缺少加密参数
        // 应该依赖main.dart中的初始化
      }
    }
  }

  // 保存 token
  Future<void> saveToken(String token) async {
    if(!_initialized) await init();
    await _box.put(_tokenKey, token);
  }

  // 获取 token
  Future<String?> getToken() async {
    if(!_initialized) await init();
    return _box.get(_tokenKey);
  }

  // 清除 token
  Future<void> clearToken() async {
    if(!_initialized) await init();
    await _box.delete(_tokenKey);
    // 移除 _box.close() 调用，保持 Box 在应用生命周期内打开
    // Box 应该只在应用退出时关闭
  }
}
