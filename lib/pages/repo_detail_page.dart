import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/toast_utils.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/common/widgets/skeleton_loader.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/commits_tab.dart';
import 'package:ghclient/pages/repo_detail/contributors_tab.dart';
import 'package:ghclient/pages/repo_detail/issues_tab.dart';
import 'package:ghclient/pages/repo_detail/overview_tab.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:flutter_octicons/flutter_octicons.dart';

import '../common/utils/app_log.dart';

class RepoPage extends ConsumerStatefulWidget {
  final Repo repo;
  final String token;
  const RepoPage({super.key, required this.repo, required this.token});

  @override
  ConsumerState<RepoPage> createState() => _ConsumerRepoPageState();
}

class _ConsumerRepoPageState extends ConsumerState<RepoPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // 保持 Tab 切换时的状态，防止重建
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  String? readmeContent;
  bool isLoading = true;
  List<dynamic> issues = [];
  List<dynamic> commits = [];
  List<dynamic> contributors = [];

  // 刷新状态跟踪
  final Set<int> _refreshingTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchRepoDetails();
  }

  Future<void> _fetchRepoDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final responses = await Future.wait([
        githubService.getReadmeHtml(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
        ),
        githubService.getIssues(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
        ),
        githubService.getCommits(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
        ),
        githubService.getContributors(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
        ),
      ]);

      // 解构结果
      final readmeResult = responses[0] as ApiResult<String?>;
      final issuesResult = responses[1] as ApiResult<List<dynamic>>;
      final commitsResult = responses[2] as ApiResult<List<dynamic>>;
      final contributorsResult = responses[3] as ApiResult<List<dynamic>>;

      if (mounted) {
        setState(() {
          readmeContent = readmeResult.$1;

          issues = issuesResult.$1 ?? [];
          commits = commitsResult.$1 ?? [];
          contributors = contributorsResult.$1 ?? [];
        });
      }
    } catch (e, s) {
      AppLog.e('获取仓库详情失败', e, s);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// 刷新概览数据（README）
  Future<void> _refreshOverview() async {
    if (_refreshingTabs.contains(0)) return;
    setState(() {
      _refreshingTabs.add(0);
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newReadme, error) = await githubService.getReadmeHtml(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
      );

      if (error != null && mounted) {
        _showRefreshError(error);
        return;
      }

      if (mounted) {
        setState(() {
          readmeContent = newReadme;
        });
      }
    } catch (e) {
      if (mounted) {
        _showRefreshError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingTabs.remove(0);
        });
      }
    }
  }

  /// 刷新 Issues 数据
  Future<void> _refreshIssues() async {
    if (_refreshingTabs.contains(1)) return;
    setState(() {
      _refreshingTabs.add(1);
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newIssues, error) = await githubService.getIssues(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
      );

      if (error != null && mounted) {
        _showRefreshError(error);
        return;
      }

      if (mounted) {
        setState(() {
          issues = newIssues ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        _showRefreshError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingTabs.remove(1);
        });
      }
    }
  }

  /// 刷新 Commits 数据
  Future<void> _refreshCommits() async {
    if (_refreshingTabs.contains(2)) return;
    setState(() {
      _refreshingTabs.add(2);
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newCommits, error) = await githubService.getCommits(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
      );

      if (error != null && mounted) {
        _showRefreshError(error);
        return;
      }

      if (mounted) {
        setState(() {
          commits = newCommits ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        _showRefreshError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingTabs.remove(2);
        });
      }
    }
  }

  /// 刷新 Contributors 数据
  Future<void> _refreshContributors() async {
    if (_refreshingTabs.contains(3)) return;
    setState(() {
      _refreshingTabs.add(3);
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newContributors, error) = await githubService.getContributors(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
      );

      if (error != null && mounted) {
        _showRefreshError(error);
        return;
      }

      if (mounted) {
        setState(() {
          contributors = newContributors ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        _showRefreshError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingTabs.remove(3);
        });
      }
    }
  }

  /// 显示刷新失败的错误消息
  void _showRefreshError(String message) {
    if (!mounted) return;
    ToastUtils.show(
      context,
      message: '刷新失败：$message',
      type: ToastType.error,
      actionLabel: '重试',
      onAction: () {
        // 根据当前 tab 重试刷新
        switch (_tabController.index) {
          case 0:
            _refreshOverview();
            break;
          case 1:
            _refreshIssues();
            break;
          case 2:
            _refreshCommits();
            break;
          case 3:
            _refreshContributors();
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AutomaticKeepAliveClientMixin 要求调用 super.build
    super.build(context);
    return SafeScaffold(
      appBar: AppBar(
        title: Text(widget.repo.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(OctIcons.book_16, size: 20), text: '概览'),
            Tab(icon: Icon(OctIcons.issue_opened_16, size: 20), text: 'Issues'),
            Tab(icon: Icon(OctIcons.git_commit_16, size: 20), text: '提交'),
            Tab(icon: Icon(OctIcons.people_16), text: '贡献者'),
          ],
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // OverviewTab - 加载时显示骨架屏
          isLoading
              ? const SkeletonLoader(type: SkeletonType.overview)
              : OverviewTab(
                  repo: widget.repo,
                  readmeContent: readmeContent,
                  onRefresh: _refreshOverview,
                ),
          // IssuesTab - 加载时显示列表骨架屏
          isLoading
              ? const SkeletonLoader(type: SkeletonType.list)
              : IssuesTab(
                  repo: widget.repo,
                  token: widget.token,
                  initialIssues: issues,
                  onRefresh: _refreshIssues,
                ),
          // CommitsTab - 加载时显示列表骨架屏
          isLoading
              ? const SkeletonLoader(type: SkeletonType.list)
              : CommitsTab(
                  repo: widget.repo,
                  token: widget.token,
                  initialCommits: commits,
                  onRefresh: _refreshCommits,
                ),
          // ContributorsTab - 加载时显示列表骨架屏
          isLoading
              ? const SkeletonLoader(type: SkeletonType.list)
              : ContributorsTab(
                  contributors: contributors,
                  onRefresh: _refreshContributors,
                ),
        ],
      ),
    );
  }
}
