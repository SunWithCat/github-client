import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/issue_card.dart';
import 'package:url_launcher/url_launcher.dart';

class IssuesTab extends ConsumerStatefulWidget {
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
  ConsumerState<IssuesTab> createState() => _IssuesTabState();
}

class _IssuesTabState extends ConsumerState<IssuesTab>
    with AutomaticKeepAliveClientMixin {
  late List<dynamic> _issues;
  late int _page;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _issues = List.from(widget.initialIssues);
    _page = 1;
    _hasMore = _issues.length >= 10;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(IssuesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件刷新数据后，更新本地状态
    if (widget.initialIssues != oldWidget.initialIssues) {
      setState(() {
        _issues = List.from(widget.initialIssues);
        _page = 1;
        _hasMore = _issues.length >= 10;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newIssues, error) = await githubService.getIssues(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
        page: _page + 1,
      );

      if (mounted) {
        setState(() {
          if (error == null && newIssues != null && newIssues.isNotEmpty) {
            _issues.addAll(newIssues);
            _page++;
            _hasMore = newIssues.length >= 10;
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleRefresh() async {
    await widget.onRefresh();
    // didUpdateWidget 会处理数据同步和分页重置
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_issues.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: OctIcons.issue_opened_16,
              title: '没有 Issues',
              message: '这个仓库目前没有任何 Issues',
              actionLabel: '创建第一个 Issue',
              onAction: () async {
                final url = Uri.parse(
                  'https://github.com/${widget.repo.owner}/${widget.repo.name}/issues/new',
                );
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _issues.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _issues.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final issue = _issues[index];
          return IssueCard(
            issue: issue as Map<String, dynamic>,
            onTap: () async {
              final url = Uri.parse(issue['html_url']);
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
