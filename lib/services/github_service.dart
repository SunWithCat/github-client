import 'package:dio/dio.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/models/repo.dart';

// (success, error) - (T?, String?)
typedef ApiResult<T> = (T?, String?);

class GithubService {
  static const int defaultPerPage = 30;

  // 私有构造，保证全局唯一
  GithubService._();
  static final GithubService instance = GithubService._();
  late final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..interceptors.add(LogInterceptor(responseBody: true));

  // 泛型封装，处理所有异常
  Future<ApiResult<T>> _safeCall<T>(
    Future<Response> Function() apiCall,
    T Function(dynamic) mapper,
  ) async {
    try {
      final response = await apiCall();
      return (mapper(response.data), null);
    } on DioException catch (e) {
      return (null, _handleDioError(e));
    } catch (e) {
      return (null, '未知错误:$e');
    }
  }

  // 获取用户数据
  Future<ApiResult<User>> getUser(String token) async {
    return _safeCall(
      () => _dio.get(
        '/user',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => User.fromJson(data),
    );
  }

  String _handleDioError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => "连接超时啦，请检查网络 🐢",
      DioExceptionType.badResponse =>
        "服务器开小差了 (${error.response?.statusCode}) 🤯",
      _ => "网络连接不稳定 🌊",
    };
  }

  // 获取仓库列表
  Future<ApiResult<List<Repo>>> getRepos(String token, {int page = 1}) async {
    return _safeCall(
      () => _dio.get(
        '/user/repos',
        queryParameters: {'page': page, 'per_page': defaultPerPage},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => (data as List).map((e) => Repo.fromJson(e)).toList(),
    );
  }

  // 获取加星标的仓库列表
  Future<ApiResult<List<Repo>>> getStarredRepos(
    String token, {
    int page = 1,
  }) async {
    return _safeCall(
      () => _dio.get(
        '/user/starred',
        queryParameters: {'page': page, 'per_page': defaultPerPage},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => (data as List).map((e) => Repo.fromJson(e)).toList(),
    );
  }

  // 获取星标仓库总数（不需要拉取所有分页）
  Future<ApiResult<int>> getStarredReposTotalCount(String token) async {
    try {
      final response = await _dio.get(
        '/user/starred',
        queryParameters: const {'page': 1, 'per_page': 1},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final total = _extractTotalCountFromLinkHeader(
        response.headers.value('link'),
      );
      if (total != null) return (total, null);

      final data = response.data;
      if (data is List) return (data.length, null); // 仅 0 或 1（per_page=1）
      return (0, null);
    } on DioException catch (e) {
      return (null, _handleDioError(e));
    } catch (e) {
      return (null, '未知错误:$e');
    }
  }

  int? _extractTotalCountFromLinkHeader(String? linkHeader) {
    if (linkHeader == null || linkHeader.isEmpty) return null;

    final lastPageMatch = RegExp(
      r'[?&]page=(\d+)[^>]*>; rel="last"',
    ).firstMatch(linkHeader);
    if (lastPageMatch == null) return null;

    return int.tryParse(lastPageMatch.group(1)!);
  }

  // 获取用户主页
  Future<ApiResult<String?>> getProfileReadme(
    String username,
    String token,
  ) async {
    return _safeCall(
      () => _dio.get(
        '/repos/$username/$username/readme',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.raw+json',
          },
          responseType: ResponseType.plain,
        ),
      ),
      (data) => data.toString(),
    );
  }

  // 获取贡献者
  Future<ApiResult<List<dynamic>>> getContributors(
    String owner,
    String repoName,
    String token,
  ) async {
    return _safeCall(
      () => _dio.get(
        '/repos/$owner/$repoName/contributors',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => data as List<dynamic>,
    );
  }

  // 获取README
  Future<ApiResult<String?>> getReadme(
    String owner,
    String repoName,
    String token,
  ) async {
    return _safeCall(
      () => _dio.get(
        '/repos/$owner/$repoName/readme',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3.raw',
          },
        ),
      ),
      (data) => data.toString(),
    );
  }

  // 获取Issues
  Future<ApiResult<List<dynamic>>> getIssues(
    String owner,
    String repoName,
    String token, {
    int page = 1,
    int perPage = 10,
  }) async {
    return _safeCall(
      () => _dio.get(
        '/repos/$owner/$repoName/issues',
        queryParameters: {'state': 'all', 'page': page, 'per_page': perPage},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => data as List<dynamic>,
    );
  }

  // 获取最近提交
  Future<ApiResult<List<dynamic>>> getCommits(
    String owner,
    String repoName,
    String token, {
    int page = 1,
    int perPage = 10,
  }) async {
    return _safeCall(
      () => _dio.get(
        '/repos/$owner/$repoName/commits',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => data as List<dynamic>,
    );
  }

  // 获取热门/趋势仓库
  Future<ApiResult<List<Repo>>> getTrendingRepos(
    String token, {
    String timeRange = 'monthly',
  }) async {
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

    return _safeCall(
      () => _dio.get(
        '/search/repositories',
        queryParameters: {
          'q': 'created:>$formattedDate',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 30,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => (data['items'] as List).map((e) => Repo.fromJson(e)).toList(),
    );
  }

  // 搜索仓库
  Future<ApiResult<List<Repo>>> searchRepos(
    String token,
    String query, {
    int page = 1,
  }) async {
    return _safeCall(
      () => _dio.get(
        '/search/repositories',
        queryParameters: {'q': query, 'page': page, 'per_page': 30},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
      (data) => (data['items'] as List).map((e) => Repo.fromJson(e)).toList(),
    );
  }
}
