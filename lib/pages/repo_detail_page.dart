import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
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
      print('获取仓库详情失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(
                    repo: widget.repo,
                    readmeContent: readmeContent,
                    preprocessedReadme: _preprocessedReadme,
                    styleSheet: _cachedStyleSheet,
                  ),
                  IssuesTab(
                    repo: widget.repo,
                    token: widget.token,
                    initialIssues: issues,
                  ),
                  CommitsTab(
                    repo: widget.repo,
                    token: widget.token,
                    initialCommits: commits,
                  ),
                  ContributorsTab(contributors: contributors),
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
          isDark ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade100,
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
      // 引用块样式 - 核心优化点 ⭐
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
                ? Colors.lightBlue.shade300.withOpacity(0.5)
                : Colors.blue.shade700.withOpacity(0.5),
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

  const OverviewTab({
    super.key,
    required this.repo,
    this.readmeContent,
    this.preprocessedReadme,
    this.styleSheet,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = widget.repo;
    final readmeContent = widget.readmeContent;
    final preprocessedReadme = widget.preprocessedReadme;
    final styleSheet = widget.styleSheet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repo.description != null && repo.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        repo.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildStatItem(
                        OctIcons.star_fill_16,
                        repo.starCount.toString(),
                        '星标',
                      ),
                      _buildStatItem(
                        OctIcons.repo_forked_16,
                        repo.forkCount.toString(),
                        '分支',
                      ),
                      if (repo.language != null)
                        _buildStatItem(OctIcons.code_16, repo.language!, '语言'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://github.com/${repo.owner}/${repo.name}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(OctIcons.mark_github_16),
                    label: const Text('在GitHub上查看'),
                  ),
                ],
              ),
            ),
          ),
          if (readmeContent != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'README',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: RepaintBoundary(
                  child: MarkdownBody(
                    data: preprocessedReadme ?? '',
                    selectable: false, // 性能优化：对于大文档，禁用选择可提升滑动性能
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
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('此仓库没有README文件'),
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
        placeholder:
            (context, url) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    alt ?? '图片加载失败',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: icon == OctIcons.star_fill_16 ? Colors.yellow.shade700 : null,
        ),
        const SizedBox(width: 4),
        Text('$value $label'),
      ],
    );
  }
}

class IssuesTab extends ConsumerStatefulWidget {
  final Repo repo;
  final String token;
  final List<dynamic> initialIssues;

  const IssuesTab({
    super.key,
    required this.repo,
    required this.token,
    required this.initialIssues,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_issues.isEmpty) return const Center(child: Text('没有 Issues'));

    return ListView.builder(
      controller: _scrollController,
      itemCount: _issues.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _issues.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final issue = _issues[index];
        final isOpen = issue['state'] == 'open';

        return ListTile(
          leading: Icon(
            isOpen ? OctIcons.issue_opened_16 : OctIcons.issue_closed_16,
            color: isOpen ? Colors.green : Colors.purple,
          ),
          title: Text(issue['title']),
          subtitle: Text('#${issue['number']} 由 ${issue['user']['login']} 创建'),
          onTap: () async {
            final url = Uri.parse(issue['html_url']);
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
        );
      },
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

  const CommitsTab({
    super.key,
    required this.repo,
    required this.token,
    required this.initialCommits,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_commits.isEmpty) return const Center(child: Text('没有提交记录'));

    return ListView.builder(
      controller: _scrollController,
      itemCount: _commits.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _commits.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final commit = _commits[index];
        final commitInfo = commit['commit'];
        final author = commitInfo['author'];
        final committer = commit['author'] ?? {'login': author['name']};
        return ListTile(
          leading:
              committer['avatar_url'] != null
                  ? CircleAvatar(
                    backgroundImage: NetworkImage(committer['avatar_url']),
                  )
                  : const CircleAvatar(child: Icon(OctIcons.person_16)),
          title: Text(
            commitInfo['message'].toString().split('\n').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${committer['login'] ?? author['name']} 提交于 ${_formatDate(author['date'])}',
          ),
          onTap: () async {
            final url = Uri.parse(commit['html_url']);
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ContributorsTab extends StatelessWidget {
  final List<dynamic> contributors;

  const ContributorsTab({super.key, required this.contributors});

  @override
  Widget build(BuildContext context) {
    if (contributors.isEmpty) return const Center(child: Text('没有贡献者信息'));
    return ListView.builder(
      itemCount: contributors.length,
      itemBuilder: (context, index) {
        final contributor = contributors[index];
        final String? avatarUrl = contributor['avatar_url'];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          ),
          title: Text(contributor['login']),
          subtitle: Text('贡献：${contributor['contributions']}次'),
          onTap: () async {
            final url = Uri.parse(contributor['html_url']);
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
        );
      },
    );
  }
}

String _formatDate(String dateString) {
  final date = DateTime.parse(dateString).toLocal();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
}
