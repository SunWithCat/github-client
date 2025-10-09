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
  Future<List<Repo>> getRepos(String token, {int page = 1}) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/user/repos',
      queryParameters: {'page': page, 'per_page': 30},
    );
    return (response.data as List).map((e) => Repo.fromJson(e)).toList();
  }

  // 获取加星标的仓库列表
  Future<List<Repo>> getStarredRepos(String token, {int page = 1}) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/user/starred',
      queryParameters: {'page': page, 'per-page': 30},
    );
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

  // 获取贡献者
  Future<List<dynamic>> getContributors(
    String owner,
    String repoName,
    String token,
  ) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/repos/$owner/$repoName/contributors',
    );
    return response.data;
  }

  // 获取README
  Future<String?> getReadme(String owner, String repoName, String token) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/repos/$owner/$repoName/readme',
      options: Options(headers: {'Accept': 'application/vnd.github.v3.raw'}),
    );
    return response.data.toString();
  }

  // 获取Issues
  Future<List<dynamic>> getIssues(
    String owner,
    String repoName,
    String token, {
    int page = 1,
    int perPage = 10,
  }) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/repos/$owner/$repoName/issues',
      queryParameters: {'state': 'all', 'page': page, 'per_page': perPage},
    );
    return response.data;
  }

  // 获取最近提交
  Future<List<dynamic>> getCommits(
    String owner,
    String repoName,
    String token, {
    int page = 1,
    int perPage = 10,
  }) async {
    _configureDio(token);
    final response = await _dio.get(
      'https://api.github.com/repos/$owner/$repoName/commits',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data;
  }

  // 配置请求头
  void _configureDio(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // 获取热门/趋势仓库
  Future<List<Repo>> getTrendingRepos(
    String token, {
    String timeRange = 'monthly',
  }) async {
    _configureDio(token);
    DateTime sinceDate;
    switch (timeRange) {
      case 'daily':
        sinceDate = DateTime.now().subtract(const Duration(days: 1));
        break;
      case 'weekly':
        sinceDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case 'monthly':
      default:
        sinceDate = DateTime.now().subtract(const Duration(days: 30));
        break;
    }
    final formattedDate =
        '${sinceDate.year}-${sinceDate.month.toString().padLeft(2, '0')}-${sinceDate.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      'https://api.github.com/search/repositories',
      queryParameters: {
        'q': 'created:>$formattedDate', // 查询条件：创建于最近30天
        'sort': 'stars', // 按星标数排序
        'order': 'desc', // 降序排列
        'per_page': 30, // 每页数量
      },
    );
    return (response.data['items'] as List)
        .map((e) => Repo.fromJson(e))
        .toList();
  }
}
