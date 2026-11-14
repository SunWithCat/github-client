import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/link_utils.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/paginated_tab_list_view.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/pr_card.dart';

class PullRequestsTab extends ConsumerWidget {
  final Repo repo;
  final String token;
  final List<dynamic> initialPullRequests;
  final Future<void> Function() onRefresh;

  const PullRequestsTab({
    super.key,
    required this.repo,
    required this.token,
    required this.initialPullRequests,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const perPage = 10;

    return PaginatedTabListView<dynamic>(
      key: ValueKey((repo.owner, repo.name)),
      initialItems: initialPullRequests,
      fetchPage: (page) async {
        final githubService = ref.read(githubServiceProvider);
        final (pullRequests, error) = await githubService.getPullRequests(
          repo.owner,
          repo.name,
          token,
          page: page,
          perPage: perPage,
        );
        if (error != null || pullRequests == null) {
          throw StateError(error ?? '未获取到 Pull Requests 数据');
        }
        return pullRequests;
      },
      hasMoreForPage: (items) => items.length >= perPage,
      itemBuilder: (context, pr) => PrCard(
        pr: pr as Map<String, dynamic>,
        onTap: () {
          openExternalUrl(context, pr['html_url']?.toString() ?? '');
        },
      ),
      emptyState: EmptyState(
        icon: OctIcons.git_pull_request_16,
        title: '没有 Pull Requests',
        message: '这个仓库目前没有任何 PR',
        actionLabel: '创建第一个 PR',
        onAction: () {
          openExternalUrl(
            context,
            'https://github.com/${repo.owner}/${repo.name}/compare',
          );
        },
      ),
      onRefresh: onRefresh,
    );
  }
}
