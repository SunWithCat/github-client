import 'package:flutter/material.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/models/repo.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown/markdown.dart' as md;

class RepoPage extends StatefulWidget {
  final Repo repo;
  final String token;
  const RepoPage({super.key, required this.repo, required this.token});

  @override
  State<RepoPage> createState() => _RepoPageState();
}

class _RepoPageState extends State<RepoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _issuesScrollController = ScrollController();
  final _commitsScrollController = ScrollController();
  String? readmeContent;
  bool isLoading = true;
  List<dynamic> issues = [];
  List<dynamic> commits = [];
  List<dynamic> contributors = [];

  // 分页加载相关状态
  bool isLoadingMore = false;
  int issuesPage = 1;
  int commitsPage = 1;
  bool hasMoreIssues = true;
  bool hasMoreCommits = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _issuesScrollController.addListener(_onIssuesScroll);
    _commitsScrollController.addListener(_onCommitsScroll);
    _fetchRepoDetails();
  }

  void _onIssuesScroll() {
    if (_issuesScrollController.position.pixels ==
        _issuesScrollController.position.maxScrollExtent) {
      _loadMoreIssues();
    }
  }

  void _onCommitsScroll() {
    if (_commitsScrollController.position.pixels ==
        _commitsScrollController.position.maxScrollExtent) {
      _loadMoreCommits();
    }
  }

  Future<void> _loadMoreIssues() async {
    if (isLoadingMore || !hasMoreIssues) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final githubService = GithubService.instance;
      final (newIssues, error) = await githubService.getIssues(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
        page: issuesPage + 1,
      );

      if (mounted) {
        setState(() {
          if (error != null) {
            print('加载更多 Issues 失败：$error');
          } else if (newIssues == null || newIssues.isEmpty) {
            hasMoreIssues = false;
          } else {
            issues.addAll(newIssues);
            issuesPage++;
          }
        });
      }
    } catch (e) {
      print('加载更多 Issues 失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreCommits() async {
    if (isLoadingMore || !hasMoreCommits) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final githubService = GithubService.instance;
      final (newCommits, error) = await githubService.getCommits(
        widget.repo.owner,
        widget.repo.name,
        widget.token,
        page: commitsPage + 1,
      );

      if (mounted) {
        setState(() {
          if (error != null) {
            print('加载更多提交记录失败：$error');
          } else if (newCommits == null || newCommits.isEmpty) {
            hasMoreCommits = false;
          } else {
            commits.addAll(newCommits);
            commitsPage++;
          }
        });
      }
    } catch (e) {
      print('加载更多提交记录失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchRepoDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final githubService = GithubService.instance;
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
          issues = issuesResult.$1 ?? [];
          commits = commitsResult.$1 ?? [];
          contributors = contributorsResult.$1 ?? [];
          if (issues.length < 10) {
            hasMoreIssues = false;
          }
          if (commits.length < 10) {
            hasMoreCommits = false;
          }
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
    _issuesScrollController.dispose();
    _commitsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildOverviewTab(),
                  _buildIssuesTab(),
                  _buildCommitsTab(),
                  _buildContributorsTab(),
                ],
              ),
    );
  }

  Widget _buildOverviewTab() {
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
                  if (widget.repo.description != null &&
                      widget.repo.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        widget.repo.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  Row(
                    children: [
                      _buildStatItem(
                        OctIcons.star_fill_16,
                        widget.repo.starCount.toString(),
                        '星标',
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        OctIcons.repo_forked_16,
                        widget.repo.forkCount.toString(),
                        '分支',
                      ),
                      const SizedBox(width: 16),
                      if (widget.repo.language != null)
                        _buildStatItem(
                          OctIcons.code_16,
                          widget.repo.language!,
                          '语言',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://github.com/${widget.repo.owner}/${widget.repo.name}',
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
                child: SelectionArea(
                  child: MarkdownBody(
                    data: _preprocessMarkdownContent(readmeContent!),
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                    onTapLink: (text, href, title) {
                      launchUrl(Uri.parse(href!));
                    },
                    // imageBuilder: (uri, title, alt) {
                    //   return _buildMarkdownImage(uri, title, alt);
                    // },
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

  Widget _buildIssuesTab() {
    if (issues.isEmpty && !isLoading) {
      return const Center(child: Text('没有 Issues'));
    }

    return ListView.builder(
      controller: _issuesScrollController,
      itemCount: issues.length + (hasMoreIssues || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == issues.length) {
          // 加载更多指示器
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child:
                isLoadingMore
                    ? const CircularProgressIndicator()
                    : hasMoreIssues
                    ? const Text('下拉加载更多')
                    : const Text('没有更多了'),
          );
        }

        final issue = issues[index];
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
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        );
      },
    );
  }

  Widget _buildCommitsTab() {
    if (commits.isEmpty && !isLoading) {
      return const Center(child: Text('没有提交记录'));
    }

    return ListView.builder(
      controller: _commitsScrollController,
      itemCount: commits.length + (hasMoreCommits || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == commits.length) {
          // 加载更多指示器
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child:
                isLoadingMore
                    ? const CircularProgressIndicator()
                    : hasMoreCommits
                    ? const Text('下拉加载更多')
                    : const Text('没有更多了'),
          );
        }

        final commit = commits[index];
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
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        );
      },
    );
  }

  Widget _buildContributorsTab() {
    if (contributors.isEmpty) {
      return const Center(child: Text('没有贡献者信息'));
    }
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
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        );
      },
    );
  }

  String _preprocessMarkdownContent(String content) {
    // 处理各种格式的 HTML img 标签，将其转换为 Markdown 格式
    return content.replaceAllMapped(
      RegExp(r'<img[^>]*>', caseSensitive: false),
      (match) {
        final imgTag = match.group(0) ?? '';

        // 简单的字符串查找方法提取 src
        String src = '';
        int srcStart = imgTag.toLowerCase().indexOf('src=');
        if (srcStart != -1) {
          int quoteStart = imgTag.indexOf('"', srcStart);
          if (quoteStart == -1) {
            quoteStart = imgTag.indexOf("'", srcStart);
          }
          if (quoteStart != -1) {
            int quoteEnd = imgTag.indexOf(imgTag[quoteStart], quoteStart + 1);
            if (quoteEnd != -1) {
              src = imgTag.substring(quoteStart + 1, quoteEnd);
            }
          }
        }

        // 简单的字符串查找方法提取 alt
        String alt = '图片';
        int altStart = imgTag.toLowerCase().indexOf('alt=');
        if (altStart != -1) {
          int quoteStart = imgTag.indexOf('"', altStart);
          if (quoteStart == -1) {
            quoteStart = imgTag.indexOf("'", altStart);
          }
          if (quoteStart != -1) {
            int quoteEnd = imgTag.indexOf(imgTag[quoteStart], quoteStart + 1);
            if (quoteEnd != -1) {
              alt = imgTag.substring(quoteStart + 1, quoteEnd);
            }
          }
        }

        if (src.isEmpty) {
          return imgTag; // 如果没有 src，保持原样
        }

        // 将 HTML img 转换为 Markdown 格式
        return '![$alt]($src)';
      },
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
}

String _formatDate(String dateString) {
  final date = DateTime.parse(dateString).toLocal();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
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
