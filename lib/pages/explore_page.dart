import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/search_page.dart';

/// 探索页：使用 ConsumerStatefulWidget 来支持有状态组件
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  bool _isLoading = true;
  List<Repo> _trendingRepos = [];
  String _selectedTimeRange = 'monthly';
  DateTime _loadingCompleteTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchTrendingRepos();
  }

  Future<void> _fetchTrendingRepos() async {
    setState(() {
      _isLoading = true;
    });
    // 🔄 使用 ref.read 获取 token
    final token = ref.read(tokenProvider);
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    try {
      // 🔄 使用 ref.read 获取 GitHub 服务
      final githubService = ref.read(githubServiceProvider);
      final (repos, error) = await githubService.getTrendingRepos(
        token,
        timeRange: _selectedTimeRange,
      );

      if (mounted) {
        setState(() {
          if (error != null) {
            debugPrint('加载热门仓库失败：$error'); // 实际项目中这里可以弹 Toast
            // 保持 _trendingRepos 不变或清空，视需求而定
          } else {
            _trendingRepos = repos ?? [];
            _loadingCompleteTime = DateTime.now(); // 记录加载完成时间
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载热门仓库发生未知错误：$e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTimeRangeChanged(String timeRange) {
    if (_selectedTimeRange != timeRange) {
      setState(() {
        _selectedTimeRange = timeRange;
        _trendingRepos = []; // 清空数据
      });
      _fetchTrendingRepos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeScaffold(
      appBar: AppBar(
        title: const Text('探索'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              icon: const Icon(OctIcons.search_16, size: 20),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [const Color(0xFF0D1117), const Color(0xFF010409)]
                    : [const Color(0xFFF6F8FA), const Color(0xFFFFFFFF)],
            stops: const [0.0, 1.0],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchTrendingRepos,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return isDark
                                ? const Color(0xFF1F6FEB)
                                : const Color(0xFF0969DA);
                          }
                          return null;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return theme.colorScheme.onSurface;
                        }),
                        side: WidgetStateProperty.all(BorderSide.none),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 'daily',
                          label: Text('今日'),
                          icon: Icon(OctIcons.flame_16, size: 14),
                        ),
                        ButtonSegment(
                          value: 'weekly',
                          label: Text('本周'),
                          icon: Icon(OctIcons.rocket_16, size: 14),
                        ),
                        ButtonSegment(
                          value: 'monthly',
                          label: Text('本月'),
                          icon: Icon(OctIcons.pulse_16, size: 14),
                        ),
                      ],
                      selected: {_selectedTimeRange},
                      onSelectionChanged: (newSelection) {
                        _onTimeRangeChanged(newSelection.first);
                      },
                    ),
                  ),
                ),
              ),
              if (_isLoading)
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_trendingRepos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          OctIcons.telescope_16,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无趋势数据',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20, top: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final repo = _trendingRepos[index];
                      return _AnimatedRepoItem(
                        repo: repo,
                        index: index,
                        loadingCompleteTime: _loadingCompleteTime,
                      );
                    }, childCount: _trendingRepos.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedRepoItem extends StatefulWidget {
  final Repo repo;
  final int index;
  final DateTime loadingCompleteTime;

  const _AnimatedRepoItem({
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
    final delay = isInitialLoad ? widget.index * 80 : 0;
    final duration = isInitialLoad ? 600 : 300;

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
