import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/commit_card.dart';
import 'package:ghclient/pages/repo_detail/date_separator.dart';
import 'package:url_launcher/url_launcher.dart';

class CommitsTab extends ConsumerStatefulWidget {
  final Repo repo;
  final String token;
  final List<dynamic> initialCommits;
  final Future<void> Function() onRefresh;

  const CommitsTab({
    super.key,
    required this.repo,
    required this.token,
    required this.initialCommits,
    required this.onRefresh,
  });

  @override
  ConsumerState<CommitsTab> createState() => _CommitsTabState();
}

class _CommitsTabState extends ConsumerState<CommitsTab>
    with AutomaticKeepAliveClientMixin {
  late List<dynamic> _commits;
  late int _page;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _commits = List.from(widget.initialCommits);
    _page = 1;
    _hasMore = _commits.length >= 10;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CommitsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件刷新数据后，更新本地状态
    if (widget.initialCommits != oldWidget.initialCommits) {
      setState(() {
        _commits = List.from(widget.initialCommits);
        _page = 1;
        _hasMore = _commits.length >= 10;
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
      final (newCommits, error) = await githubService.getCommits(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
        page: _page + 1,
      );

      if (mounted) {
        setState(() {
          if (error == null && newCommits != null && newCommits.isNotEmpty) {
            _commits.addAll(newCommits);
            _page++;
            _hasMore = newCommits.length >= 10;
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

  DateTime? _getCommitDate(dynamic commit) {
    try {
      final commitInfo = commit['commit'];
      if (commitInfo == null) return null;

      final author = commitInfo['author'];
      if (author == null) return null;

      final dateStr = author['date']?.toString();
      if (dateStr == null || dateStr.isEmpty) return null;

      final dateTime = DateTime.parse(dateStr);
      // 返回仅日期部分（去除时间）
      return DateTime(dateTime.year, dateTime.month, dateTime.day);
    } catch (e) {
      return null;
    }
  }

  List<Widget> _buildGroupedCommitList() {
    final List<Widget> items = [];
    DateTime? lastDate;

    for (int i = 0; i < _commits.length; i++) {
      final commit = _commits[i];
      final commitDate = _getCommitDate(commit);

      // 如果日期变化，插入日期分隔符
      if (commitDate != null && (lastDate == null || commitDate != lastDate)) {
        items.add(DateSeparator(date: commitDate));
        lastDate = commitDate;
      }

      items.add(
        CommitCard(
          commit: commit as Map<String, dynamic>,
          onTap: () async {
            final url = Uri.parse(commit['html_url']);
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
        ),
      );
    }

    // 如果还有更多数据，添加加载指示器
    if (_hasMore) {
      items.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_commits.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: OctIcons.git_commit_16,
              title: '没有提交记录',
              message: '这个仓库目前没有任何提交历史',
            ),
          ),
        ),
      );
    }

    // 使用 ListView 展示按日期分组的提交列表
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _buildGroupedCommitList(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
