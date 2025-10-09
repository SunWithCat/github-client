import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/profile_change.dart';
import 'package:provider/provider.dart';

class ReposPage extends StatefulWidget {
  const ReposPage({super.key});

  @override
  State<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends State<ReposPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Repo> _repos = [];
  List<Repo> _filteredRepos = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _repos = context.read<ProfileChange>().profile.repos;
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
    super.dispose();
    _scrollController.dispose();
    _searchController.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final profileChange = context.read<ProfileChange>();
      final newRepos = await profileChange.loadMoreRepos();
      if (newRepos.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _repos = profileChange.profile.repos;
          _hasMore = profileChange.profile.reposHasMore;
          _filterRepos(_searchController.text);
        });
      }
    } catch (e) {
      print('加载更多仓库失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 搜索过滤
  void _filterRepos(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = _repos; // 当搜索框为空时，显示所有仓库
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
            hintText: '搜索你的仓库...',
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
      return const Center(child: Text('你还没有任何仓库'));
    }
    if (_searchController.text.isNotEmpty && _filteredRepos.isEmpty) {
      return const Center(child: Text('没有找到匹配的仓库'));
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredRepos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredRepos.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return RepoItem(repo: _filteredRepos[index]);
      },
    );
  }
}
