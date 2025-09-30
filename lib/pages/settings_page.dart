import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghclient/profile_change.dart';
import 'package:ghclient/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final githubBlue = Color(0xFF0969DA);
    final profileUser = context.read<ProfileChange>().profile.user;
    final avatarUrl = profileUser?.avatarUrl;
    final userLogin = profileUser?.login;
    final userName = profileUser?.name;

    const String developer = 'SunWithCat';
    const projectUrl = 'https://github.com/SunWithCat/github-client';
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(height: 32),
          _buildSectionTitle(context, '帐号'),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl!),
                ),
                trailing: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('退出登录'),
                          content: const Text('你确定要退出这个帐号吗？'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // 先关闭对话框
                                Navigator.pop(context);
                                // 然后执行退出登录
                                Provider.of<ProfileChange>(
                                  context,
                                  listen: false,
                                ).logout();
                                // 由于退出后 `isLoggedIn` 会变为 false, main.dart 中的逻辑会
                                // 自动将页面切换到 LoginPage，这里不需要手动跳转了。
                              },
                              child: const Text(
                                '确定',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(OctIcons.sign_out_16),
                ),
                title: Text(userLogin!),
                subtitle: Text(
                  userName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                onTap: () {},
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, '主题'),
          _buildSettingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text(
                  '深色模式',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                subtitle: Text(isDarkMode ? '已开启' : '已关闭'),
                value: isDarkMode,
                onChanged: (bool value) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
                secondary: Icon(
                  isDarkMode ? OctIcons.moon_16 : OctIcons.sun_16,
                ),
                activeColor: githubBlue,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, '关于'),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: const Icon(OctIcons.versions_16),
                title: const Text('版本'),
                subtitle: const Text('1.0.0'),
                onTap: () {
                  Fluttertoast.showToast(
                    msg: "目前已是最新版~",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('开发者'),
                subtitle: const Text(developer),
                trailing: const Icon(OctIcons.chevron_right_16),
                onTap: () async {
                  final url = Uri.parse('https://github.com/$developer');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              ListTile(
                leading: const Icon(OctIcons.mark_github_16),
                title: const Text('项目地址'),
                subtitle: const Text('开放源代码'),
                trailing: const Icon(OctIcons.chevron_right_16),
                onTap: () async {
                  final url = Uri.parse(projectUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(context, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Column(children: children),
      ),
    );
  }
}
