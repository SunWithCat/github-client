import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/app_log.dart';
import 'package:ghclient/common/utils/toast_utils.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/utils/debouncer.dart';

class ReposPage extends ConsumerStatefulWidget {
  const ReposPage({super.key});

  @override
  ConsumerState<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends ConsumerState<ReposPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Repo> _repos = [];
  List<Repo> _filteredRepos = [];
  bool _isLoading = false;
  bool _hasMore = true;

  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _repos = profile.repos;
    _filteredRepos = _repos;
    _hasMore = profile.reposHasMore;
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final notifier = ref.read(profileProvider.notifier);
      final newRepos = await notifier.loadMoreRepos();
      if (!mounted) return;
      final profileState = ref.read(profileProvider);
      setState(() {
        _repos = profileState.repos;
        _hasMore = profileState.reposHasMore && newRepos.isNotEmpty;
        _filterRepos(_searchController.text);
      });
    } catch (e, s) {
      AppLog.e('加载更多仓库失败', e, s);
      if (mounted) {
        ToastUtils.show(
          context,
          message: '加载更多失败，请稍后重试',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      await ref.read(profileProvider.notifier).refreshData();
    } catch (e, s) {
      AppLog.e('刷新仓库失败', e, s);
      if (mounted) {
        ToastUtils.show(context, message: '刷新失败，请稍后重试', type: ToastType.error);
      }
    }
    if (!mounted) return;
    final profile = ref.read(profileProvider);
    setState(() {
      _repos = profile.repos;
      _hasMore = profile.reposHasMore;
      _filterRepos(_searchController.text);
    });
  }

  void _filterRepos(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = _repos;
      });
    } else {
      final filtered = _repos.where((repo) {
        return repo.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
      setState(() {
        _filteredRepos = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      appBar: AppBar(
        title: const Text('我的仓库'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _searchController,
              hintText: '搜索你的仓库...',
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: '清空',
                    onPressed: () {
                      _searchController.clear();
                      _filterRepos('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              shape: WidgetStatePropertyAll(
                RoundedSuperellipseBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (value) {
                _debouncer.run(() {
                  _filterRepos(value);
                });
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_repos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(
              icon: OctIcons.repo_16,
              title: '还没有仓库',
              message: '下拉刷新，或去 GitHub 创建一个新仓库',
            ),
          ],
        ),
      );
    }
    if (_searchController.text.isNotEmpty && _filteredRepos.isEmpty) {
      return const EmptyState(
        icon: OctIcons.search_16,
        title: '没有找到匹配的仓库',
        message: '试试其他关键词',
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 500,
        itemCount: _filteredRepos.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredRepos.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return RepoItem(
            repo: _filteredRepos[index],
            showVisibilityBadge: true,
          );
        },
      ),
    );
  }
}
