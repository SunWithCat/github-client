import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/app_log.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/services/github_service.dart';

class ExploreState {
  final Map<String, List<Repo>> reposCache;
  final Map<String, bool> loadingStatus;
  final Map<String, String?> errorStatus;
  final String selectedTimeRange;
  final DateTime loadingCompleteTime;

  ExploreState({
    this.reposCache = const {},
    this.loadingStatus = const {},
    this.errorStatus = const {},
    this.selectedTimeRange = 'monthly',
    DateTime? loadingCompleteTime,
  }) : loadingCompleteTime = loadingCompleteTime ?? DateTime.now();

  List<Repo>? get currentRepos => reposCache[selectedTimeRange];

  /// 当前选中范围是否正在加载
  bool get isCurrentLoading => loadingStatus[selectedTimeRange] ?? false;

  /// 当前选中范围的错误信息
  String? get currentError => errorStatus[selectedTimeRange];
  ExploreState copyWith({
    Map<String, List<Repo>>? reposCache,
    Map<String, bool>? loadingStatus,
    Map<String, String?>? errorStatus,
    String? selectedTimeRange,
    DateTime? loadingCompleteTime,
  }) {
    return ExploreState(
      reposCache: reposCache ?? this.reposCache,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      errorStatus: errorStatus ?? this.errorStatus,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
      loadingCompleteTime: loadingCompleteTime ?? this.loadingCompleteTime,
    );
  }
}

class ExploreNotifier extends Notifier<ExploreState> {
  late final GithubService _githubService;

  @override
  ExploreState build() {
    _githubService = ref.read(githubServiceProvider);
    return ExploreState();
  }

  void selectTimeRange(String timeRange) {
    if (state.selectedTimeRange != timeRange) {
      state = state.copyWith(selectedTimeRange: timeRange);
      if (!state.reposCache.containsKey(timeRange) &&
          !(state.loadingStatus[timeRange] ?? false)) {
        fetchTrending(timeRange);
      }
    }
  }

  Future<void> fetchTrending(
    String timeRange, {
    bool forceRefresh = false,
  }) async {
    // 如果已经有缓存且不是强制下拉刷新，直接命中缓存，0ms 瞬发！
    if (!forceRefresh && state.reposCache.containsKey(timeRange)) {
      return;
    }
    // 设置对应范围的 loading 状态
    state = state.copyWith(
      loadingStatus: {...state.loadingStatus, timeRange: true},
      errorStatus: {...state.errorStatus, timeRange: null},
    );
    final token = ref.read(tokenProvider);
    if (token == null) {
      state = state.copyWith(
        loadingStatus: {...state.loadingStatus, timeRange: false},
        errorStatus: {...state.errorStatus, timeRange: '登录已失效，请重新登录后再探索'},
      );
      return;
    }
    try {
      final (repos, error) = await _githubService.getTrendingRepos(
        token,
        timeRange: timeRange,
      );
      if (error != null) {
        AppLog.e('加载热门仓库失败：$error');
        state = state.copyWith(
          loadingStatus: {...state.loadingStatus, timeRange: false},
          errorStatus: {...state.errorStatus, timeRange: error},
        );
      } else {
        state = state.copyWith(
          reposCache: {...state.reposCache, timeRange: repos ?? []},
          loadingStatus: {...state.loadingStatus, timeRange: false},
          errorStatus: {...state.errorStatus, timeRange: null},
          loadingCompleteTime: DateTime.now(),
        );
      }
    } catch (e, s) {
      AppLog.e('加载热门仓库发生未知错误', e, s);
      state = state.copyWith(
        loadingStatus: {...state.loadingStatus, timeRange: false},
        errorStatus: {...state.errorStatus, timeRange: '加载失败，请稍后重试'},
      );
    }
  }
}

final exploreProvider = NotifierProvider<ExploreNotifier, ExploreState>(
  ExploreNotifier.new,
);
