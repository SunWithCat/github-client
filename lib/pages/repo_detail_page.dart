import 'package:flutter/material.dart';
import 'package:ghclient/models/repo.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_octicons/flutter_octicons.dart';

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
  String? readmeContent;
  bool isLoading = true;
  List<dynamic> issues = [];
  List<dynamic> commits = [];
  List<dynamic> contributors = [];

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
      final githubService = GithubService();
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
      if (mounted) {
        setState(() {
          readmeContent = responses[0] as String?;
          issues = responses[1] as List<dynamic>;
          commits = responses[2] as List<dynamic>;
          contributors = responses[3] as List<dynamic>;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repo.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description,size: 20,), text: '概览'),
            Tab(
              icon: Icon(OctIcons.issue_opened_16,size: 20,),
              text: 'Issues',
            ),
            Tab(
              icon: Icon(OctIcons.git_commit_16,size: 20),
              text: '提交',
            ),
            Tab(icon: Icon(Icons.people), text: '贡献者'),
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
                        Icons.star,
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
                        _buildStatItem(Icons.code, widget.repo.language!, '语言'),
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
                child: MarkdownBody(data: readmeContent!),
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
    if (issues.isEmpty) {
      return const Center(child: Text('没有 Issues'));
    }
    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final isOpen = issue['state'] == 'open';

        return ListTile(
          leading: Icon(
            isOpen ? Icons.error_outline : Icons.check_circle_outline,
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
    if (commits.isEmpty) {
      return const Center(child: Text('没有提交记录'));
    }
    return ListView.builder(
      itemCount: commits.length,
      itemBuilder: (context, index) {
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
                  : const CircleAvatar(child: Icon(Icons.person)),
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
        color: icon == Icons.star ? Colors.yellow.shade700 : null,
      ),
      const SizedBox(width: 4),
      Text('$value $label'),
    ],
  );
}
