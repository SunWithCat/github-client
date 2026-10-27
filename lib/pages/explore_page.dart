import 'package:fluid_glass/fluid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/liquid_glass_navbar.dart';
import 'package:go_router/go_router.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  static const List<String> _timeRanges = ['daily', 'weekly', 'monthly'];
  final LayerBackdrop _backdrop = LayerBackdrop();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(exploreProvider);
      if (state.currentRepos == null && !state.isCurrentLoading) {
        ref
            .read(exploreProvider.notifier)
            .fetchTrending(state.selectedTimeRange);
      }
    });
  }

  @override
  void dispose() {
    _backdrop.dispose();
    super.dispose();
  }

  void _onTimeRangeChanged(String timeRange) {
    ref.read(exploreProvider.notifier).selectTimeRange(timeRange);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final exploreState = ref.watch(exploreProvider);
    final repos = exploreState.currentRepos ?? [];
    final isLoading = exploreState.isCurrentLoading;
    final errorMessage = exploreState.currentError;
    final selectedIndex = _timeRanges
        .indexOf(exploreState.selectedTimeRange)
        .clamp(0, 2);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('探索'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainer,
                    ]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerLow,
                    ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: '搜索仓库',
              onPressed: () {
                context.push('/search');
              },
              icon: const Icon(OctIcons.search_16, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: BackdropLayer(
              backdrop: _backdrop,
              motionPixelRatio: MediaQuery.devicePixelRatioOf(context) * 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0D1117), const Color(0xFF010409)]
                        : [const Color(0xFFF6F8FA), const Color(0xFFFFFFFF)],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: RefreshIndicator(
                  edgeOffset: 60,
                  onRefresh: () => ref
                      .read(exploreProvider.notifier)
                      .fetchTrending(
                        exploreState.selectedTimeRange,
                        forceRefresh: true,
                      ),
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 84)),
                      if (isLoading && repos.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '正在探索...',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (errorMessage != null && repos.isEmpty)
                        SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.wifi_off_outlined,
                            title: '加载失败',
                            message: errorMessage,
                            actionLabel: '重试',
                            actionIcon: Icons.refresh,
                            onAction: () => ref
                                .read(exploreProvider.notifier)
                                .fetchTrending(
                                  exploreState.selectedTimeRange,
                                  forceRefresh: true,
                                ),
                          ),
                        )
                      else if (repos.isEmpty)
                        SliverFillRemaining(
                          child: EmptyState(
                            icon: OctIcons.telescope_16,
                            title: '暂无趋势数据',
                            message: '换个时间范围，或者下拉刷新试试',
                            actionLabel: '重新加载',
                            actionIcon: Icons.refresh,
                            onAction: () => ref
                                .read(exploreProvider.notifier)
                                .fetchTrending(
                                  exploreState.selectedTimeRange,
                                  forceRefresh: true,
                                ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 20, top: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final repo = repos[index];
                              return _AnimatedRepoItem(
                                key: ValueKey(
                                  '${exploreState.selectedTimeRange}_${repo.cloneUrl}',
                                ),
                                repo: repo,
                                index: index,
                                loadingCompleteTime:
                                    exploreState.loadingCompleteTime,
                              );
                            }, childCount: repos.length),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: LiquidGlassTheme(
              colors:
                  (isDark ? LiquidGlassColors.dark : LiquidGlassColors.light)
                      .copyWith(
                        accent: isDark
                            ? const Color(0xFF1F6FEB)
                            : const Color(0xFF0969DA),
                        container: isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.6)
                            : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      ),
              child: LiquidGlassNavBar(
                backdrop: _backdrop,
                selectedIndex: selectedIndex,
                onSelected: (int index) =>
                    _onTimeRangeChanged(_timeRanges[index]),
                items: const [
                  GlassNavItem(label: '今日', icon: OctIcons.flame_16),
                  GlassNavItem(label: '本周', icon: OctIcons.rocket_16),
                  GlassNavItem(label: '本月', icon: OctIcons.pulse_16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRepoItem extends StatefulWidget {
  final Repo repo;
  final int index;
  final DateTime loadingCompleteTime;

  const _AnimatedRepoItem({
    super.key,
    required this.repo,
    required this.index,
    required this.loadingCompleteTime,
  });

  @override
  State<_AnimatedRepoItem> createState() => _AnimatedRepoItemState();
}

class _AnimatedRepoItemState extends State<_AnimatedRepoItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 判断是否是初始加载阶段（例如加载完成后的 1 秒内）
    final isInitialLoad =
        DateTime.now().difference(widget.loadingCompleteTime).inMilliseconds <
        800;

    // 只有初始加载时才使用级联延迟，否则快速显示
    final delay = isInitialLoad ? (widget.index.clamp(0, 8) * 50) : 0;
    final duration = isInitialLoad ? 400 : 240;

    _controller = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RepoItem(repo: widget.repo),
      ),
    );
  }
}
