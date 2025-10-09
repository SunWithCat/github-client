import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/profile_change.dart';
import 'package:provider/provider.dart';

class StarredReposPage extends StatefulWidget {
  const StarredReposPage({super.key});

  @override
  State<StarredReposPage> createState() => _StarredReposPageState();
}

class _StarredReposPageState extends State<StarredReposPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Repo> _repos = [];
  List<Repo> _filteredRepos = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _repos = context.read<ProfileChange>().profile.starredRepos;
    _filteredRepos = _repos;
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final profileChange = context.read<ProfileChange>();
      final newRepos = await profileChange.loadMoreStarredRepos();
      if (newRepos.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _repos = profileChange.profile.starredRepos;
          _hasMore = profileChange.profile.starredReposHasMore;
          _filterRepos(_searchController.text);
        });
      }
    } catch (e) {
      print('加载更多星标仓库失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterRepos(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = _repos;
      });
    } else {
      final filtered =
          _repos.where((repo) {
            return repo.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
      setState(() {
        _filteredRepos = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          onChanged: _filterRepos,
          decoration: InputDecoration(
            hintText: '搜索你的星标仓库...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              _filterRepos('');
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_repos.isEmpty) {
      return const Center(child: Text('你还没有给任何仓库添加星标'));
    }
    if (_searchController.text.isNotEmpty && _filteredRepos.isEmpty) {
      return const Center(child: Text('没有找到匹配的星标仓库'));
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredRepos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 如果是最后一项，并且还有更多数据，则显示加载指示器
        if (index == _filteredRepos.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // 否则，显示仓库信息
        return RepoItem(repo: _filteredRepos[index]);
      },
    );
  }
}
