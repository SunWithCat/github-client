import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/profile_change.dart';
import 'package:provider/provider.dart';

class StarredReposPage extends StatelessWidget {
  const StarredReposPage({super.key});

  @override
  Widget build(BuildContext context) {
    final starredRepos = context.watch<ProfileChange>().profile.starredRepos;
    return Scaffold(
      appBar: AppBar(title: const Text('我的星标')),
      body:
          starredRepos.isEmpty
              ? const Center(child: Text('你还没有给任何仓库加星标'))
              : ListView.builder(
                itemCount: starredRepos.length,
                itemBuilder: (context, index) {
                  return RepoItem(repo: starredRepos[index]);
                },
              ),
    );
  }
}
