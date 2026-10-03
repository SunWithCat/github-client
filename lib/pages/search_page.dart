import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/app_log.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Repo> _repos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _currentQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textEditingController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _repos = [];
      _page = 1;
      _hasMore = true;
      _currentQuery = trimmed;
      _errorMessage = null;
    });

    final token = ref.read(tokenProvider);
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '登录已失效，请重新登录';
        });
      }
      return;
    }

    try {
      final githubService = ref.read(githubServiceProvider);
      final (repos, error) = await githubService.searchRepos(
        token,
        _currentQuery,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        if (error != null) {
          AppLog.e('搜索仓库失败：$error');
          _errorMessage = error;
        } else {
          _repos = repos ?? [];
          _hasMore = (repos?.length ?? 0) >= 30;
        }
      });
    } catch (e, s) {
      AppLog.e('搜索仓库失败', e, s);
      if (mounted) {
        setState(() {
          _errorMessage = '搜索失败，请稍后重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _currentQuery.isEmpty ||
        _errorMessage != null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final token = ref.read(tokenProvider);
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      return;
    }

    final nextPage = _page + 1;
    try {
      final githubService = ref.read(githubServiceProvider);
      final (newRepos, error) = await githubService.searchRepos(
        token,
        _currentQuery,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        if (error != null) {
          AppLog.e('加载更多搜索结果失败：$error');
        } else if (newRepos == null || newRepos.isEmpty) {
          _hasMore = false;
        } else {
          _repos.addAll(newRepos);
          _page = nextPage;
          _hasMore = newRepos.length >= 30;
        }
      });
    } catch (e, s) {
      AppLog.e('加载更多搜索结果失败', e, s);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _repos.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_outlined,
        title: '搜索失败',
        message: _errorMessage!,
        actionLabel: '重试',
        actionIcon: Icons.refresh,
        onAction: () => _performSearch(_currentQuery),
      );
    }
    if (_repos.isEmpty) {
      return EmptyState(
        icon: OctIcons.search_16,
        title: _currentQuery.isEmpty ? '搜索仓库' : '没有找到匹配的仓库',
        message: _currentQuery.isEmpty ? '开始搜索你感兴趣的仓库吧！' : '试试更短或不同的关键词',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _repos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _repos.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return RepoItem(repo: _repos[index], showVisibilityBadge: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      appBar: AppBar(
        title: const Text('搜索仓库'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _textEditingController,
              hintText: '输入关键词搜索...',
              leading: Icon(
                OctIcons.search_16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              trailing: [
                if (_textEditingController.text.isNotEmpty)
                  IconButton(
                    tooltip: '清空',
                    onPressed: () {
                      _textEditingController.clear();
                      setState(() {
                        _repos = [];
                        _currentQuery = '';
                        _errorMessage = null;
                        _hasMore = true;
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
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
}
