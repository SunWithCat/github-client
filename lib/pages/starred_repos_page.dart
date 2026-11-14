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

  bool _isLoading = false;
  String _searchQuery = '';
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
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
    if (_isLoading || !ref.read(profileProvider).starredReposHasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(profileProvider.notifier).loadMoreStarredRepos();
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
  }

  @override
  Widget build(BuildContext context) {
    final repos = ref.watch(
      profileProvider.select((state) => state.starredRepos),
    );
    final keyword = _searchQuery.toLowerCase();
    final filteredRepos = keyword.isEmpty
        ? repos
        : repos.where((repo) {
            return repo.name.toLowerCase().contains(keyword);
          }).toList();
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
                      setState(() {
                        _searchQuery = '';
                      });
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
              onChanged: (_) {
                _debouncer.run(() {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = _searchController.text;
                  });
                });
              },
            ),
          ),
          Expanded(child: _buildBody(repos, filteredRepos)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Repo> repos, List<Repo> filteredRepos) {
    if (repos.isEmpty) {
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
    if (_searchQuery.isNotEmpty && filteredRepos.isEmpty) {
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
        itemCount: filteredRepos.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredRepos.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return RepoItem(
            repo: filteredRepos[index],
            showVisibilityBadge: true,
          );
        },
      ),
    );
  }
}
