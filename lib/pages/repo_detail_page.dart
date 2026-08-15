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
  List<String> _branches = [];
  late String _currentBranch;

  // 刷新状态跟踪
  final Set<int> _refreshingTabs = {};

  @override
  void initState() {
    super.initState();
    _currentBranch = widget.repo.defaultBranch ?? 'main';
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
          ref: _currentBranch,
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
          sha: _currentBranch,
        ),
        githubService.getContributors(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
        ),
        githubService.getBranches(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
          perPage: 100,
        ),
      ]);

      // 解构结果
      final readmeResult = responses[0] as ApiResult<String?>;
      final issuesResult = responses[1] as ApiResult<List<dynamic>>;
      final commitsResult = responses[2] as ApiResult<List<dynamic>>;
      final contributorsResult = responses[3] as ApiResult<List<dynamic>>;
      final branchesResult = responses[4] as ApiResult<List<dynamic>>;

      if (mounted) {
        setState(() {
          readmeContent = readmeResult.$1;
          issues = issuesResult.$1 ?? [];
          commits = commitsResult.$1 ?? [];
          contributors = contributorsResult.$1 ?? [];
          _branches = (branchesResult.$1 ?? [])
              .map((b) => b['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          if (_branches.isNotEmpty && !_branches.contains(_currentBranch)) {
            _branches.insert(0, _currentBranch);
          }
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
        ref: _currentBranch,
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
        sha: _currentBranch,
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

  Future<void> _onBranchChanged(String newBranch) async {
    if (newBranch == _currentBranch) return;
    setState(() {
      _currentBranch = newBranch;
      isLoading = true;
    });
    try {
      final githubService = ref.read(githubServiceProvider);
      final responses = await Future.wait([
        githubService.getReadmeHtml(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
          ref: _currentBranch,
        ),
        githubService.getCommits(
          widget.repo.owner,
          widget.repo.name,
          widget.token,
          sha: _currentBranch,
        ),
      ]);
      final readmeRes = responses[0] as ApiResult<String?>;
      final commitsRes = responses[1] as ApiResult<List<dynamic>>;
      if (mounted) {
        setState(() {
          readmeContent = readmeRes.$1;
          commits = commitsRes.$1 ?? [];
        });
      }
    } catch (e, s) {
      AppLog.e('切换分支失败', e, s);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 分支选择器
  void _showBranchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBranches = _branches
                .where(
                  (b) => b.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // 顶部拖动条
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 标题
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(OctIcons.git_branch_16, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            '选择分支',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_branches.length} 个分支',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 搜索框
                    if (_branches.length > 5)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '搜索分支...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    // 分支列表
                    Expanded(
                      child: filteredBranches.isEmpty
                          ? Center(
                              child: Text(
                                _branches.isEmpty ? '暂无分支信息' : '未找到匹配分支',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredBranches.length,
                              itemBuilder: (context, index) {
                                final branch = filteredBranches[index];
                                final isCurrent = branch == _currentBranch;
                                final isDefault =
                                    branch == widget.repo.defaultBranch;
                                return ListTile(
                                  leading: Icon(
                                    OctIcons.git_branch_16,
                                    size: 16,
                                    color: isCurrent
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade600,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          branch,
                                          style: TextStyle(
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isCurrent
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isDefault)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            'default',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: isCurrent
                                      ? Icon(
                                          Icons.check,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _onBranchChanged(branch);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(OctIcons.git_branch_16, size: 14),
              label: Text(_currentBranch, style: const TextStyle(fontSize: 12)),
              onPressed: _showBranchPicker,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
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
                  branch: _currentBranch,
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
                  branch: _currentBranch,
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
