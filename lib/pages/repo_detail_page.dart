import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/common/widgets/skeleton_loader.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/commit_card.dart';
import 'package:ghclient/pages/repo_detail/date_separator.dart';
import 'package:ghclient/pages/repo_detail/issue_card.dart';
import 'package:ghclient/pages/repo_detail/repo_stats_card.dart';
import 'package:ghclient/pages/repo_detail/contributor_card.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown/markdown.dart' as md;

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

  // 缓存 Markdown 样式表和预处理内容
  MarkdownStyleSheet? _cachedStyleSheet;
  String? _preprocessedReadme;

  // 刷新状态跟踪
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchRepoDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在主题变化时重建样式表
    _cachedStyleSheet = _buildMarkdownStyleSheet(context);
  }

  Future<void> _fetchRepoDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final githubService = ref.read(githubServiceProvider);
      final responses = await Future.wait([
        githubService.getReadme(
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
          // 性能优化：在数据加载时就预处理 Markdown，而不是每次 build
          _preprocessedReadme =
              readmeContent != null
                  ? _preprocessMarkdownContent(readmeContent!)
                  : null;
          issues = issuesResult.$1 ?? [];
          commits = commitsResult.$1 ?? [];
          contributors = contributorsResult.$1 ?? [];
        });
      }
    } catch (e) {
      debugPrint('获取仓库详情失败：$e');
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
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final githubService = ref.read(githubServiceProvider);
      final (newReadme, error) = await githubService.getReadme(
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
          _preprocessedReadme =
              readmeContent != null
                  ? _preprocessMarkdownContent(readmeContent!)
                  : null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showRefreshError(e.toString());
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// 刷新 Issues 数据
  Future<void> _refreshIssues() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

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
      _isRefreshing = false;
    }
  }

  /// 刷新 Commits 数据
  Future<void> _refreshCommits() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

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
      _isRefreshing = false;
    }
  }

  /// 刷新 Contributors 数据
  Future<void> _refreshContributors() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

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
      _isRefreshing = false;
    }
  }

  /// 显示刷新失败的错误消息
  void _showRefreshError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('刷新失败：$message'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () {
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
        ),
      ),
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
                  preprocessedReadme: _preprocessedReadme,
                  styleSheet: _cachedStyleSheet,
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

  String _preprocessMarkdownContent(String content) {
    // 处理各种格式 of HTML img tags
    return content.replaceAllMapped(
      RegExp(r'<img[^>]*>', caseSensitive: false),
      (match) {
        final imgTag = match.group(0) ?? '';

        // 简单的字符串查找方法提取 src
        String src = '';
        int srcStart = imgTag.toLowerCase().indexOf('src=');
        if (srcStart != -1) {
          int quoteStart = imgTag.indexOf('"', srcStart);
          if (quoteStart == -1) quoteStart = imgTag.indexOf("'", srcStart);
          if (quoteStart != -1) {
            int quoteEnd = imgTag.indexOf(imgTag[quoteStart], quoteStart + 1);
            if (quoteEnd != -1) {
              src = imgTag.substring(quoteStart + 1, quoteEnd);
            }
          }
        }
        String alt = '图片';
        int altStart = imgTag.toLowerCase().indexOf('alt=');
        if (altStart != -1) {
          int quoteStart = imgTag.indexOf('"', altStart);
          if (quoteStart == -1) quoteStart = imgTag.indexOf("'", altStart);
          if (quoteStart != -1) {
            int quoteEnd = imgTag.indexOf(imgTag[quoteStart], quoteStart + 1);
            if (quoteEnd != -1) {
              alt = imgTag.substring(quoteStart + 1, quoteEnd);
            }
          }
        }
        if (src.isEmpty) return imgTag;
        return '![$alt]($src)';
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseSheet = MarkdownStyleSheet.fromTheme(theme);

    final blockquoteDecoration = BoxDecoration(
      color:
          isDark ? Colors.grey.shade800.withValues(alpha: 0.6) : Colors.grey.shade100,
      border: Border(
        left: BorderSide(
          color: isDark ? Colors.amber.shade600 : Colors.blueGrey.shade400,
          width: 4,
        ),
      ),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
    );

    // 代码块装饰 - 更柔和的背景色
    final codeblockDecoration = BoxDecoration(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        width: 1,
      ),
    );

    // 行内代码样式
    final codeTextStyle = TextStyle(
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      color: isDark ? Colors.orange.shade300 : Colors.deepOrange.shade700,
      fontFamily: 'monospace',
      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
    );

    return baseSheet.copyWith(
      // 引用块样式
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: blockquoteDecoration,
      blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),

      // 代码块样式
      code: codeTextStyle,
      codeblockDecoration: codeblockDecoration,
      codeblockPadding: const EdgeInsets.all(12),

      // 表格样式
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      tableBody: theme.textTheme.bodyMedium,
      tableBorder: TableBorder.all(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        width: 1,
      ),
      tableHeadAlign: TextAlign.center,
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      // 链接样式 - 更醒目
      a: TextStyle(
        color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
        decoration: TextDecoration.underline,
        decorationColor:
            isDark
                ? Colors.lightBlue.shade300.withValues(alpha: 0.5)
                : Colors.blue.shade700.withValues(alpha: 0.5),
      ),

      // 水平分隔线
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class OverviewTab extends StatefulWidget {
  final Repo repo;
  final String? readmeContent;
  final String? preprocessedReadme;
  final MarkdownStyleSheet? styleSheet;
  final Future<void> Function() onRefresh;

  const OverviewTab({
    super.key,
    required this.repo,
    this.readmeContent,
    this.preprocessedReadme,
    this.styleSheet,
    required this.onRefresh,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 控制 README 是否展开
  bool _isReadmeExpanded = false;
  // 默认显示的字符数限制
  static const int _collapsedCharLimit = 2000;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = widget.repo;
    final readmeContent = widget.readmeContent;
    final preprocessedReadme = widget.preprocessedReadme;
    final styleSheet = widget.styleSheet;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用新的 RepoStatsCard 组件
            RepoStatsCard(repo: repo),
            
            const SizedBox(height: 16),
            if (readmeContent != null) ...[
              _buildReadmeSection(context, preprocessedReadme, styleSheet),
            ] else
              _buildEmptyReadmeCard(context),
          ],
        ),
      ),
    );
  }

  /// 获取截断后的 README 内容
  String _getTruncatedReadme(String? content) {
    if (content == null || content.length <= _collapsedCharLimit) {
      return content ?? '';
    }
    if (_isReadmeExpanded) {
      return content;
    }
    // 在字符限制附近找一个换行符截断，避免截断在单词中间
    int cutIndex = content.lastIndexOf('\n', _collapsedCharLimit);
    if (cutIndex < _collapsedCharLimit * 0.7) {
      cutIndex = _collapsedCharLimit;
    }
    return content.substring(0, cutIndex);
  }

  /// 判断 README 是否需要展开按钮
  bool _needsExpansion(String? content) {
    return content != null && content.length > _collapsedCharLimit;
  }

  /// 构建 README 区域，包含清晰的 section header 和适当间距
  Widget _buildReadmeSection(
    BuildContext context,
    String? preprocessedReadme,
    MarkdownStyleSheet? styleSheet,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final needsExpansion = _needsExpansion(preprocessedReadme);
    final displayContent = _getTruncatedReadme(preprocessedReadme);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  OctIcons.book_16,
                  size: 18,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'README',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // README Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: MarkdownBody(
                  data: displayContent,
                  selectable: false,
                  styleSheet: styleSheet,
                  onTapLink: (text, href, title) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                  imageBuilder: _buildMarkdownImage,
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 展开/收起按钮
          if (needsExpansion)
            InkWell(
              onTap: () {
                setState(() {
                  _isReadmeExpanded = !_isReadmeExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800.withValues(alpha: 0.3)
                      : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isReadmeExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isReadmeExpanded ? '收起' : '展开全部',
                      style: TextStyle(
                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建空 README 状态卡片
  Widget _buildEmptyReadmeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  OctIcons.book_16,
                  size: 18,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'README',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Empty State
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    OctIcons.file_16,
                    size: 32,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此仓库没有 README 文件',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownImage(Uri uri, String? title, String? alt) {
    String imageUrl = uri.toString();

    // 如果是相对路径，转换为 GitHub raw 文件 URL
    if (!imageUrl.startsWith('http')) {
      // 移除开头的 './' 或直接以文件名开始的情况
      if (imageUrl.startsWith('./')) {
        imageUrl = imageUrl.substring(2);
      }
      // 构建 GitHub raw 文件 URL
      imageUrl =
          'https://raw.githubusercontent.com/${widget.repo.owner}/${widget.repo.name}/main/$imageUrl';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

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

class ContributorsTab extends StatefulWidget {
  final List<dynamic> contributors;
  final Future<void> Function() onRefresh;

  const ContributorsTab({
    super.key,
    required this.contributors,
    required this.onRefresh,
  });

  @override
  State<ContributorsTab> createState() => _ContributorsTabState();
}

class _ContributorsTabState extends State<ContributorsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 获取项目总贡献数（所有贡献者贡献数之和）
  int get totalContributions {
    if (widget.contributors.isEmpty) return 0;
    int total = 0;
    for (final contributor in widget.contributors) {
      total += (contributor['contributions'] ?? 0) as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.contributors.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: OctIcons.people_16,
              title: '没有贡献者信息',
              message: '这个仓库目前没有贡献者数据',
            ),
          ),
        ),
      );
    }

    final total = totalContributions;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.contributors.length,
        itemBuilder: (context, index) {
          final contributor = widget.contributors[index];

          return ContributorCard(
            contributor: contributor as Map<String, dynamic>,
            totalContributions: total,
            onTap: () async {
              final url = Uri.parse(contributor['html_url']);
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
          );
        },
      ),
    );
  }
}
