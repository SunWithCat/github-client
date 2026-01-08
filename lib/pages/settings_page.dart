import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final githubBlue = const Color(0xFFB3D4FC);
    final profileUser = ref.watch(userProvider);

    if (profileUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarUrl = profileUser.avatarUrl;
    final userLogin = profileUser.login;
    final userName = profileUser.name;

    const String developer = 'SunWithCat';
    const projectUrl = 'https://github.com/SunWithCat/github-client';
    return SafeScaffold(
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
                leading: Hero(
                  tag: 'user_avatar',
                  child: CachedNetworkImage(
                    key: ValueKey(avatarUrl),
                    imageUrl: avatarUrl,
                    memCacheWidth: 80, // 40 * 2 (for high DPI)
                    memCacheHeight: 80,
                    imageBuilder:
                        (context, imageProvider) =>
                            CircleAvatar(backgroundImage: imageProvider),
                    placeholder:
                        (context, url) =>
                            CircleAvatar(backgroundColor: Colors.transparent),
                    errorWidget:
                        (context, url, error) => CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person),
                        ),
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('退出登录'),
                          content: const Text('你确定要退出这个帐号吗？'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(profileProvider.notifier).logout();
                                final navigator = Navigator.of(dialogContext);
                                navigator.pop();
                                navigator.pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
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
                title: Text(userLogin),
                subtitle: Text(
                  userName ?? 'Unknown Name',
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
                  // 🔄 使用 ref.read 获取 notifier 来切换主题
                  ref.read(themeProvider.notifier).toggleTheme();
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
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              ListTile(
                leading: const Icon(OctIcons.person_16),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
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

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias, // 裁切多余的边角
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(children: children),
    );
  }
}
