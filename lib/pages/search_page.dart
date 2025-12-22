import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';

/// 搜索页：使用 ConsumerStatefulWidget 来支持有状态组件
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    // 收起键盘
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _repos = [];
      _page = 1;
      _hasMore = true;
      _currentQuery = query;
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
      final (repos, error) = await githubService.searchRepos(
        token,
        _currentQuery,
        page: _page,
      );
      if (mounted) {
        setState(() {
          if (error != null) {
            debugPrint('搜索仓库失败：$error');
            _repos = [];
          } else {
            _repos = repos ?? [];
          }
        });
      }
    } catch (e) {
      debugPrint('搜索仓库失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _currentQuery.isEmpty) {
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
    try {
      _page++;
      final githubService = ref.read(githubServiceProvider);
      final (newRepos, error) = await githubService.searchRepos(
        token,
        _currentQuery,
        page: _page,
      );
      if (mounted) {
        setState(() {
          if (error != null) {
            debugPrint('加载更多搜索结果失败：$error');
            // 可以在这里处理错误，比如不增加页码
            _page--;
          } else if (newRepos == null || newRepos.isEmpty) {
            _hasMore = false;
          } else {
            _repos.addAll(newRepos);
          }
        });
      }
    } catch (e) {
      debugPrint('加载更多搜索结果失败：$e');
    } finally {
      if (mounted) {
        _isLoadingMore = false;
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_repos.isEmpty) {
      return Center(
        child: Text(_currentQuery.isEmpty ? '开始搜索你感兴趣的仓库吧！' : '没有找到匹配的仓库'),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _repos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _repos.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child:
                  _isLoadingMore
                      ? const CircularProgressIndicator()
                      : const Text('没有更多了'),
            ),
          );
        }
        return RepoItem(repo: _repos[index]);
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textEditingController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入关键词搜索...',
                prefixIcon: Icon(OctIcons.search_16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (query) {
                _performSearch(query);
              },
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
}
