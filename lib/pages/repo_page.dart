import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ghclient/models/repo.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRepoDetails();
  }

  Future<void> _fetchRepoDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer ${widget.token}';

      // 获取README内容
      try {
        final readmeResponse = await dio.get(
          'https://api.github.com/repos/${widget.repo.owner}/${widget.repo.name}/readme',
          options: Options(
            headers: {'Accept': 'application/vnd.github.v3.raw'},
          ),
        );
        if (readmeResponse.statusCode == 200) {
          setState(() {
            readmeContent = readmeResponse.data.toString();
          });
        }
      } catch (e) {
        print('获取README失败:$e');
      }

      // 获取issues
      try {
        final issuesResponse = await dio.get(
          'https://api.github.com/repos/${widget.repo.owner}/${widget.repo.name}/issues?state=all&per_page=10',
        );
        if (issuesResponse.statusCode == 200) {
          setState(() {
            issues = issuesResponse.data;
          });
        }
      } catch (e) {
        print('获取issues失败:$e');
      }

      // 获取最近提交
      try {
        final commitsResponse = await dio.get(
          'https://api.github.com/repos/${widget.repo.owner}/${widget.repo.name}/commits?per_page=10',
        );
        if (commitsResponse.statusCode == 200) {
          setState(() {
            commits = commitsResponse.data;
          });
        }
      } catch (e) {
        print('获取最近提交失败:$e');
      }
    } catch (e) {
      print('获取仓库详情失败:$e');
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
            Tab(icon: Icon(Icons.description), text: '概览'),
            Tab(
              icon: FaIcon(FontAwesomeIcons.fileCircleExclamation, size: 20),
              text: 'Issues',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.codeBranch, size: 20),
              text: '提交',
            ),
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
                        FontAwesomeIcons.codeFork,
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
                    icon: const FaIcon(FontAwesomeIcons.github),
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
}

String _formatDate(String dateString) {
  final date = DateTime.parse(dateString);
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
