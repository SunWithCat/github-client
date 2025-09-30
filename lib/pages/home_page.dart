import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:ghclient/pages/search_page.dart';
import 'package:ghclient/pages/settings_page.dart';
import 'package:ghclient/pages/starred_repos_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../profile_change.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 格式化日期显示
  String formatJoinDate(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final date = DateTime.parse(createdAt).toLocal();
      return '${date.year}年${date.month}月${date.day}日加入';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProfileChange>();
    final user = notifier.profile.user;
    final brightness = Theme.of(context).brightness;
    final profileReadme = notifier.profile.profileReadme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child:
                user == null
                    ? const Text('未能找到用户信息')
                    : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 显示头像
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name ?? user.login,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                    ),
                                    Text(
                                      '@${user.login}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    // 显示加入GitHub的日期
                                    if (user.createdAt != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatJoinDate(user.createdAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SettingsPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.settings),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(OctIcons.mark_github_16, size: 20),
                              const SizedBox(width: 8),
                              Text('${user.publicRepos}个公开的仓库'),
                              const Spacer(), // 添加Spacer以将按钮推到右侧
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchPage(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.folder_open), // 使用文件夹图标
                                label: Text('仓库'), // 添加文本指示
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StarredReposPage(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.star, color: Colors.amber),
                                label: Text('星标'),
                              ),
                            ],
                          ),
                          if (user.bio != null)
                            Text(user.bio!, style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text('${user.followers} followers'),
                              const SizedBox(width: 8),
                              Text('·'),
                              const SizedBox(width: 8),
                              Text('${user.following} following'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 地址/博客
                          if (user.location != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(user.location!),
                              ],
                            ),
                          const Divider(height: 32),
                          // README
                          if (profileReadme != null)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12.0,
                                ), // 设置圆角
                              ),
                              color: Theme.of(context).cardTheme.color,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: MarkdownBody(
                                  data: profileReadme,
                                  onTapLink: (text, href, title) {
                                    // 打开链接
                                    if (href != null) {
                                      launchUrl(Uri.parse(href));
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
