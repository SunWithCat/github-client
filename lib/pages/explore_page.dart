import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/profile_change.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _isLoading = true;
  List<Repo> _trendingRepos = [];

  @override
  void initState() {
    super.initState();
    _fetchTrendingRepos();
  }

  Future<void> _fetchTrendingRepos() async {
    setState(() {
      _isLoading = true;
    });
    final token = context.read<ProfileChange>().profile.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final githubService = GithubService();
      final repos = await githubService.getTrendingRepos(token);
      if (mounted) {
        setState(() {
          _trendingRepos = repos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载热门仓库失败：$e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索热门仓库'),
        actions: [
          IconButton(
            onPressed: _fetchTrendingRepos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_trendingRepos.isEmpty) {
      return const Center(
        child: Text('未能加载热门仓库，请稍后再试', style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.builder(
      itemCount: _trendingRepos.length,
      itemBuilder: (context, index) {
        return RepoItem(repo: _trendingRepos[index]);
      },
    );
  }
}
