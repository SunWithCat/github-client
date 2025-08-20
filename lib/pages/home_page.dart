import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghclient/pages/search_page.dart';
import 'package:ghclient/theme/theme_provider.dart';
import '../profile_change.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../common/widgets/repo_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProfileChange>();
    final user = notifier.profile.user;
    // final repos = notifier.profile.repos;
    final brightness = Theme.of(context).brightness;

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
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Provider.of<ThemeProvider>(
                                    context,
                                    listen: false,
                                  ).toggleTheme();
                                },
                                icon:
                                    brightness == Brightness.dark
                                        ? Icon(Icons.light_mode)
                                        : Icon(Icons.dark_mode),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('退出登录'),
                                        content: const Text('你确定要退出这个帐号吗？'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text(
                                              '取消',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Provider.of<ProfileChange>(
                                                context,
                                                listen: false,
                                              ).logout();
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              '确定',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.logout),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.github, size: 20),
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
                                label: Text('查看所有仓库'), // 添加文本指示
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
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
