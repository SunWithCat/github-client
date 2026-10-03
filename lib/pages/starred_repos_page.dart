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

class StarredReposPage extends ConsumerStatefulWidget {
  const StarredReposPage({super.key});

  @override
  ConsumerState<StarredReposPage> createState() => _StarredReposPageState();
}

class _StarredReposPageState extends ConsumerState<StarredReposPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Repo> _repos = [];
  List<Repo> _filteredRepos = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _repos = profile.starredRepos;
    _filteredRepos = _repos;
    _hasMore = profile.starredReposHasMore;
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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
      final newRepos = await notifier.loadMoreStarredRepos();
      if (!mounted) return;
      final profileState = ref.read(profileProvider);
      setState(() {
        _repos = profileState.starredRepos;
        _hasMore = profileState.starredReposHasMore && newRepos.isNotEmpty;
        _filterRepos(_searchController.text);
      });
    } catch (e, s) {
      AppLog.e('加载更多星标仓库失败', e, s);
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
      AppLog.e('刷新星标仓库失败', e, s);
      if (mounted) {
        ToastUtils.show(context, message: '刷新失败，请稍后重试', type: ToastType.error);
      }
    }
    if (!mounted) return;
    final profile = ref.read(profileProvider);
    setState(() {
      _repos = profile.starredRepos;
      _hasMore = profile.starredReposHasMore;
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
        title: const Text('星标仓库'),
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
              hintText: '搜索你的星标仓库...',
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
              icon: OctIcons.star_16,
              title: '还没有星标仓库',
              message: '在仓库详情里点星标，收藏会显示在这里',
            ),
          ],
        ),
      );
    }
    if (_searchController.text.isNotEmpty && _filteredRepos.isEmpty) {
      return const EmptyState(
        icon: OctIcons.search_16,
        title: '没有找到匹配的星标仓库',
        message: '试试其他关键词',
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
