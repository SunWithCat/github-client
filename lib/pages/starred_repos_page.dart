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
  List<Repo> _filteredRepos = [];
  final TextEditingController _searchController = TextEditingController();

  void _filterRepos(String query) {
    final starredRepos = context.watch<ProfileChange>().profile.starredRepos;
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = starredRepos;
      });
    } else {
      final filtered =
          starredRepos.where((repo) {
            return repo.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
      setState(() {
        _filteredRepos = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final starredRepos = context.watch<ProfileChange>().profile.starredRepos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          onChanged: _filterRepos,
          decoration: InputDecoration(
            hintText: '搜索你的星标仓库...',
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
      body:
          starredRepos.isEmpty
              ? const Center(child: Text('你还没有给任何仓库添加星标'))
              : _searchController.text.isEmpty
              ? ListView.builder(
                itemCount: starredRepos.length,
                itemBuilder: (context, index) {
                  return RepoItem(repo: starredRepos[index]);
                },
              )
              : (_filteredRepos.isEmpty
                  ? Center(child: const Text("没有找到匹配的星标仓库"))
                  : ListView.builder(
                    itemCount: _filteredRepos.length,
                    itemBuilder: (context, index) {
                      return RepoItem(repo: _filteredRepos[index]);
                    },
                  )),
    );
  }
}
