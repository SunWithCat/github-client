import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/widgets/github_markdown.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/pages/explore_page.dart';
import 'package:ghclient/pages/repos_page.dart';
import 'package:ghclient/pages/settings_page.dart';
import 'package:ghclient/pages/starred_repos_page.dart';

class HomePage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final brightness = Theme.of(context).brightness;
    final profileReadme = profileState.profileReadme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: SafeScaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExplorePage()),
            );
          },
          backgroundColor: const Color(0xFFB3D4FC),
          foregroundColor: const Color(0xFF003566),
          icon: Icon(OctIcons.telescope_16),
          label: const Text('探索'),
        ),
        body: RefreshIndicator(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child:
                    user == null
                        ? _buildEmptyState(context)
                        : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUserHeader(context, user),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(OctIcons.mark_github_16, size: 20),
                                  const SizedBox(width: 8),
                                  Text('${user.publicRepos}个公开的仓库'),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReposPage(),
                                        ),
                                      );
                                    },
                                    icon: Icon(OctIcons.repo_16),
                                    label: Text('仓库'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => StarredReposPage(),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      OctIcons.star_fill_16,
                                      color: Colors.yellow.shade700,
                                    ),
                                    label: Text('星标'),
                                  ),
                                ],
                              ),
                              if (user.bio != null)
                                Text(
                                  user.bio!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    OctIcons.people_16,
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
                              profileReadme != null
                                  ? Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: GitHubMarkdown(
                                        data: profileReadme,
                                        owner: user.login,
                                        repo: user.login, // profile readme 仓库名与用户名相同
                                        selectable: true,
                                      ),
                                    ),
                                  )
                                  : const Center(
                                    child: Text("还没有个人主页仓库，快去添加吧~"),
                                  ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
          onRefresh: () async {
            await ref.read(profileProvider.notifier).refreshData();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '未能找到用户消息',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Hero(
              tag: 'user_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  key: ValueKey(user.avatarUrl),
                  imageUrl: user.avatarUrl,
                  memCacheWidth: 140, // 70 * 2 (for high DPI)
                  memCacheHeight: 140,
                  imageBuilder:
                      (context, imageProvider) => CircleAvatar(
                        radius: 35,
                        backgroundImage: imageProvider,
                      ),
                  placeholder:
                      (context, url) => CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.transparent,
                      ),
                  errorWidget:
                      (context, url, error) => CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(Icons.person),
                      ),
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.login,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user.login}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  if (user.createdAt != null)
                    Row(
                      children: [
                        Icon(
                          OctIcons.calendar_24,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatJoinDate(user.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
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
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }
}
