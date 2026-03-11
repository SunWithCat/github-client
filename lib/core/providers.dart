import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:ghclient/services/storage_service.dart';
import 'package:ghclient/theme/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// GitHub API 服务的 Provider（单例模式）
final githubServiceProvider = Provider<GithubService>((ref) {
  return GithubService.instance;
});

/// 本地存储服务的 Provider（单例模式）
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Profile 状态类 - 使用不可变模式管理用户相关数据
class ProfileState {
  final String? token;
  final User? user;
  final List<Repo> repos;
  final List<Repo> starredRepos;
  final int? starredReposTotalCount;
  final String? profileReadme;
  final bool isLoading;
  final int reposCurrentPage;
  final int starredReposCurrentPage;
  final bool reposHasMore;
  final bool starredReposHasMore;

  const ProfileState({
    this.token,
    this.user,
    this.repos = const [],
    this.starredRepos = const [],
    this.starredReposTotalCount,
    this.profileReadme,
    this.isLoading = true,
    this.reposCurrentPage = 1,
    this.starredReposCurrentPage = 1,
    this.reposHasMore = true,
    this.starredReposHasMore = true,
  });

  /// 便捷判断：是否已登录
  bool get isLoggedIn => token != null;

  /// 创建新状态的 copyWith 方法
  ProfileState copyWith({
    String? token,
    User? user,
    List<Repo>? repos,
    List<Repo>? starredRepos,
    int? starredReposTotalCount,
    String? profileReadme,
    bool? isLoading,
    int? reposCurrentPage,
    int? starredReposCurrentPage,
    bool? reposHasMore,
    bool? starredReposHasMore,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return ProfileState(
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      repos: repos ?? this.repos,
      starredRepos: starredRepos ?? this.starredRepos,
      starredReposTotalCount:
          starredReposTotalCount ?? this.starredReposTotalCount,
      profileReadme: profileReadme ?? this.profileReadme,
      isLoading: isLoading ?? this.isLoading,
      reposCurrentPage: reposCurrentPage ?? this.reposCurrentPage,
      starredReposCurrentPage:
          starredReposCurrentPage ?? this.starredReposCurrentPage,
      reposHasMore: reposHasMore ?? this.reposHasMore,
      starredReposHasMore: starredReposHasMore ?? this.starredReposHasMore,
    );
  }
}

/// Profile 状态管理器 - 继承自 Notifier
/// 负责管理用户登录、数据获取、缓存等核心逻辑
class ProfileNotifier extends Notifier<ProfileState> {
  // 依赖的服务
  late final GithubService _githubService;
  late final StorageService _storageService;

  @override
  ProfileState build() {
    // 在 build 中获取依赖的服务
    _githubService = ref.read(githubServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    return const ProfileState();
  }

  /// 初始化：检查缓存和自动登录
  Future<void> init() async {
    final String? accessToken = await _storageService.getToken();
    if (accessToken != null) {
      state = state.copyWith(token: accessToken);
      final bool hasCache = await _initFromCache();

      if (hasCache) {
        state = state.copyWith(isLoading: false);
        debugPrint('🚀 命中缓存，进入静默刷新模式');
        silentLogin(accessToken);
      } else {
        debugPrint('🐢 无缓存，进入常规登录模式');
        await login(accessToken);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 从缓存初始化数据
  Future<bool> _initFromCache() async {
    try {
      final user = await _storageService.getUser();
      if (user == null) return false;

      final repos = await _storageService.getRepos();
      final starred = await _storageService.getStarredRepos();
      final readme = await _storageService.getReadme();

      state = state.copyWith(
        user: user,
        repos: repos,
        starredRepos: starred,
        profileReadme: readme,
      );
      return true;
    } catch (e) {
      debugPrint('读取缓存失败：$e');
      return false;
    }
  }

  /// 保存数据到缓存
  Future<void> _saveToCache() async {
    if (state.user != null) {
      await _storageService.saveUser(state.user!);
    }
    await _storageService.saveRepos(state.repos);
    await _storageService.saveStarredRepos(state.starredRepos);
    if (state.profileReadme != null) {
      await _storageService.saveReadme(state.profileReadme!);
    }
  }

  /// 静默登录（后台刷新）
  Future<void> silentLogin(String token) async {
    try {
      await _performLoginLogic(token);
      debugPrint('静默刷新成功');
    } catch (e) {
      debugPrint('静默刷新失败：$e');
    }
  }

  /// 登录方法
  Future<void> login(String token) async {
    state = state.copyWith(token: token, isLoading: true);
    try {
      await _performLoginLogic(token);
    } catch (e) {
      debugPrint('登录或获取用户信息失败：$e');
      logout();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 提取公共的登录逻辑
  Future<void> _performLoginLogic(String token) async {
    // 获取用户信息
    final (user, error) = await _githubService.getUser(token);
    if (error != null) {
      throw Exception(error);
    }

    // ✨ 智能更新：只在关键数据变化时才更新 User
    if (state.user == null ||
        state.user!.avatarUrl != user!.avatarUrl ||
        state.user!.name != user.name ||
        state.user!.bio != user.bio ||
        state.user!.followers != user.followers ||
        state.user!.following != user.following) {
      state = state.copyWith(user: user);
    }

    final results = await Future.wait([
      _githubService.getRepos(token),
      _githubService.getStarredRepos(token, page: 1),
      _githubService.getStarredReposTotalCount(token),
      _githubService.getProfileReadme(user!.login, token),
    ]);

    final reposResult = results[0] as ApiResult<List<Repo>>;
    final starredResult = results[1] as ApiResult<List<Repo>>;
    final starredTotalCountResult = results[2] as ApiResult<int>;
    final readmeResult = results[3] as ApiResult<String?>;

    if (reposResult.$2 != null) {
      debugPrint('Repos Error: ${reposResult.$2}');
    }
    if (starredResult.$2 != null) {
      debugPrint('Starred Error: ${starredResult.$2}');
    }
    if (starredTotalCountResult.$2 != null) {
      debugPrint('Starred Total Count Error: ${starredTotalCountResult.$2}');
    }
    if (readmeResult.$2 != null) {
      debugPrint('Readme Error: ${readmeResult.$2}');
    }

    final initialRepos = reposResult.$1;
    final initialStarredRepos = starredResult.$1;

    state = state.copyWith(
      repos: initialRepos ?? state.repos,
      starredRepos: initialStarredRepos ?? state.starredRepos,
      starredReposTotalCount:
          starredTotalCountResult.$1 ?? state.starredReposTotalCount,
      profileReadme: readmeResult.$1 ?? state.profileReadme,
      reposCurrentPage: 1,
      starredReposCurrentPage: 1,
      reposHasMore:
          initialRepos != null
              ? initialRepos.length >= GithubService.defaultPerPage
              : state.reposHasMore,
      starredReposHasMore:
          initialStarredRepos != null
              ? (starredTotalCountResult.$1 != null
                    ? initialStarredRepos.length < starredTotalCountResult.$1!
                    : initialStarredRepos.length >=
                          GithubService.defaultPerPage)
              : state.starredReposHasMore,
    );

    // 🎉 获取成功后，更新缓存
    await _saveToCache();
  }

  /// 刷新数据（用于下拉刷新，不改变 loading 状态）
  Future<void> refreshData() async {
    if (state.token == null) return;
    try {
      await _performLoginLogic(state.token!);
    } catch (e) {
      debugPrint('刷新数据失败：$e');
    }
  }

  /// 退出登录
  void logout() {
    state = const ProfileState(isLoading: false);
    _storageService.clearToken();
  }

  /// 加载更多星标仓库
  Future<List<Repo>> loadMoreStarredRepos() async {
    if (state.token == null || !state.starredReposHasMore) {
      return [];
    }
    try {
      final (newRepos, error) = await _githubService.getStarredRepos(
        state.token!,
        page: state.starredReposCurrentPage + 1,
      );

      if (error != null) {
        debugPrint('加载更多星标仓库失败：$error');
        return [];
      }

      if (newRepos == null || newRepos.isEmpty) {
        state = state.copyWith(
          starredReposHasMore: false,
          starredReposTotalCount:
              state.starredReposTotalCount ?? state.starredRepos.length,
        );
      } else {
        final updatedStarredRepos = [...state.starredRepos, ...newRepos];
        final loadedAllByCount =
            state.starredReposTotalCount != null &&
            updatedStarredRepos.length >= state.starredReposTotalCount!;

        state = state.copyWith(
          starredReposCurrentPage: state.starredReposCurrentPage + 1,
          starredRepos: updatedStarredRepos,
          starredReposHasMore:
              !loadedAllByCount &&
              newRepos.length >= GithubService.defaultPerPage,
        );
      }
      return newRepos ?? [];
    } catch (e) {
      debugPrint('加载更多星标仓库失败：$e');
      return [];
    }
  }

  /// 加载更多仓库
  Future<List<Repo>> loadMoreRepos() async {
    if (state.token == null || !state.reposHasMore) {
      return [];
    }
    try {
      final (newRepos, error) = await _githubService.getRepos(
        state.token!,
        page: state.reposCurrentPage + 1,
      );

      if (error != null) {
        debugPrint('加载更多仓库失败：$error');
        return [];
      }

      if (newRepos == null || newRepos.isEmpty) {
        state = state.copyWith(reposHasMore: false);
      } else {
        state = state.copyWith(
          reposCurrentPage: state.reposCurrentPage + 1,
          repos: [...state.repos, ...newRepos],
          reposHasMore: newRepos.length >= GithubService.defaultPerPage,
        );
      }
      return newRepos ?? [];
    } catch (e) {
      debugPrint('加载更多仓库失败：$e');
      return [];
    }
  }
}

/// Profile 状态的 Provider
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});

/// 主题状态管理器
class ThemeNotifier extends Notifier<ThemeData> {
  @override
  ThemeData build() {
    // 默认使用暗色主题
    return darkMode;
  }

  /// 切换主题
  void toggleTheme() {
    state = state.brightness == Brightness.light ? darkMode : lightMode;
  }

  /// 设置特定主题
  void setTheme(ThemeData themeData) {
    state = themeData;
  }
}

/// 主题的 Provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeData>(() {
  return ThemeNotifier();
});

/// 当前用户 Provider（只读）
final userProvider = Provider<User?>((ref) {
  return ref.watch(profileProvider).user;
});

/// 当前 Token Provider（只读）
final tokenProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).token;
});

/// 是否已登录 Provider（只读）
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isLoggedIn;
});

/// 是否正在加载 Provider（只读）
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isLoading;
});

/// 应用包信息 Provider（异步）
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// 应用版本号 Provider（格式：x.y.z）
final appVersionProvider = Provider<String>((ref) {
  final packageInfoAsync = ref.watch(packageInfoProvider);
  return packageInfoAsync.when(
    data: (info) => info.version,
    loading: () => '...',
    error: (_, __) => '未知',
  );
});

/// 应用完整版本号 Provider（格式：x.y.z+buildNumber）
final appFullVersionProvider = Provider<String>((ref) {
  final packageInfoAsync = ref.watch(packageInfoProvider);
  return packageInfoAsync.when(
    data: (info) => '${info.version}+${info.buildNumber}',
    loading: () => '...',
    error: (_, __) => '未知',
  );
});
