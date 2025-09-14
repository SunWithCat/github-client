import 'package:dio/dio.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/models/repo.dart';

class GithubService {
  final Dio _dio = Dio();
  // 获取用户数据
  Future<User> getUser(String token) async {
    _configureDio(token);
    final response = await _dio.get('https://api.github.com/user');
    return User.fromJson(response.data);
  }

  // 获取仓库列表
  Future<List<Repo>> getRepos(String token) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/user/repos',
    );
    return (response.data as List).map((e) => Repo.fromJson(e)).toList();
  }

  // 获取加星标的仓库列表
  Future<List<Repo>> getStarredRepos(String token) async {
    _configureDio(token);
    final response = await _dio.get('https://api.github.com/user/starred');
    return (response.data as List).map((e) => Repo.fromJson(e)).toList();
  }

  // 获取用户主页
  Future<String?> getProfileReadme(String username, String token) async {
    try {
      _configureDio(token);
      final response = await _dio.get(
        'https://api.github.com/repos/$username/$username/readme',
        options: Options(
          headers: {'Accept': 'application/vnd.github.raw+json'},
          responseType: ResponseType.plain,
        ),
      );
      return response.data;
    } catch (e) {
      print('获取个人主页失败:$e');
      return null;
    }
  }

  // 配置请求头
  void _configureDio(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
