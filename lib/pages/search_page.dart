import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/profile_change.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // 存储过滤后的仓库列表
  List<Repo> _filteredRepos = [];
  // 用于获取输入框文本
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // final allRepos = context.read<ProfileChange>().profile.repos;
    // _filteredRepos = allRepos;
  }

  // 搜索过滤
  void _filterRepos(String query) {
    final allRepos = context.read<ProfileChange>().profile.repos;
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = allRepos; // 当搜索框为空时，显示所有仓库
      });
    } else {
      final filtered =
          allRepos.where((repo) {
            return repo.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
      setState(() {
        _filteredRepos = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRepos = context.watch<ProfileChange>().profile.repos; // 获取所有仓库
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          onChanged: _filterRepos,
          decoration: InputDecoration(
            hintText: '搜索你的仓库...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              _filterRepos('');
            },
            icon: Icon(Icons.clear),
          ),
        ],
      ),
      body:
          _searchController.text.isEmpty
              ? (allRepos.isEmpty
                  ? Center(
                      child: Text('你还没有任何仓库'),
                    )
                  : ListView.builder(
                      itemCount: allRepos.length,
                      itemBuilder: (context, index) {
                        return RepoItem(repo: allRepos[index]);
                      },
                    ))
              : (_filteredRepos.isEmpty
                  ? Center(
                      child: Text('没有找到匹配的仓库'),
                    )
                  : ListView.builder(
                      itemCount: _filteredRepos.length,
                      itemBuilder: (context, index) {
                        return RepoItem(repo: _filteredRepos[index]);
                      },
                    )),
    );
  }
}
