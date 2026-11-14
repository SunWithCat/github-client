import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/link_utils.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/paginated_tab_list_view.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/issue_card.dart';

class IssuesTab extends ConsumerWidget {
  final Repo repo;
  final String token;
  final List<dynamic> initialIssues;
  final Future<void> Function() onRefresh;

  const IssuesTab({
    super.key,
    required this.repo,
    required this.token,
    required this.initialIssues,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedTabListView<dynamic>(
      key: ValueKey((repo.owner, repo.name)),
      initialItems: initialIssues,
      fetchPage: (page) async {
        final githubService = ref.read(githubServiceProvider);
        final (issues, error) = await githubService.getIssues(
          repo.owner,
          repo.name,
          token,
          page: page,
        );
        if (error != null || issues == null) {
          throw StateError(error ?? '未获取到 Issues 数据');
        }
        return issues;
      },
      hasMoreForPage: (items) => items.isNotEmpty,
      itemBuilder: (context, issue) => IssueCard(
        issue: issue as Map<String, dynamic>,
        onTap: () {
          openExternalUrl(context, issue['html_url']?.toString() ?? '');
        },
      ),
      emptyState: EmptyState(
        icon: OctIcons.issue_opened_16,
        title: '没有 Issues',
        message: '这个仓库目前没有任何 Issues',
        actionLabel: '创建第一个 Issue',
        onAction: () {
          openExternalUrl(
            context,
            'https://github.com/${repo.owner}/${repo.name}/issues/new',
          );
        },
      ),
      onRefresh: onRefresh,
    );
  }
}
