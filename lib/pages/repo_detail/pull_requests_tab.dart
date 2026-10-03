import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/link_utils.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/pr_card.dart';

class PullRequestsTab extends ConsumerStatefulWidget {
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
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PullRequestsTabState();
}

class _PullRequestsTabState extends ConsumerState<PullRequestsTab>
    with AutomaticKeepAliveClientMixin {
  late List<dynamic> _prs;
  late int _page;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _prs = List.from(widget.initialPullRequests);
    _page = 1;
    _hasMore = _prs.length >= 10;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PullRequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPullRequests != oldWidget.initialPullRequests) {
      setState(() {
        _prs = List.from(widget.initialPullRequests);
        _page = 1;
        _hasMore = _prs.length >= 10;
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
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final giuthubService = ref.read(githubServiceProvider);
      final (newPrs, error) = await giuthubService.getPullRequests(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          if (error == null && newPrs != null && newPrs.isNotEmpty) {
            _prs.addAll(newPrs);
            _page++;
            _hasMore = newPrs.length >= 10;
          } else if (error == null) {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_prs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: OctIcons.git_pull_request_16,
              title: '没有 Pull Requests',
              message: '这个仓库目前没有任何 PR',
              actionLabel: '创建第一个 PR',
              onAction: () {
                openExternalUrl(
                  context,
                  'https://github.com/${widget.repo.owner}/${widget.repo.name}/compare',
                );
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
        itemCount: _prs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _prs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final pr = _prs[index];
          return PrCard(
            pr: pr as Map<String, dynamic>,
            onTap: () {
              openExternalUrl(context, pr['html_url']?.toString() ?? '');
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
