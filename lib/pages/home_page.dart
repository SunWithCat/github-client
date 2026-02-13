import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/github_markdown.dart';
import 'package:ghclient/common/widgets/safe_scaffold.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/my_user_model.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String formatJoinDate(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final date = DateTime.parse(createdAt).toLocal();
      return '${date.year}年${date.month}月${date.day}日加入';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: SafeScaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/explore'),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          icon: const Icon(OctIcons.telescope_16),
          label: const Text('探索'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(profileProvider.notifier).refreshData();
          },
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOut,
              child: _buildBody(context, profileState, user),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState profileState, User? user) {
    if (profileState.isLoading && user == null) {
      return ListView(
        key: const ValueKey('home_loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: const [_HomeInitialLoadingView()],
      );
    }

    if (user == null) {
      return ListView(
        key: const ValueKey('home_empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: MediaQuery.of(context).size.height * 0.68, child: const _HomeEmptyState())],
      );
    }

    return ListView(
      key: const ValueKey('home_content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _HomeHeaderCard(
          user: user,
          joinDateText: formatJoinDate(user.createdAt),
          onOpenSettings: () => context.push('/settings'),
        ).animate().fadeIn(duration: const Duration(milliseconds: 220)).slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 12),
        _HomeQuickActions(
          publicRepos: user.publicRepos,
          starredRepos: profileState.starredRepos.length,
          onOpenRepos: () => context.push('/repos'),
          onOpenStarred: () => context.push('/starred'),
        ).animate(delay: const Duration(milliseconds: 60)).fadeIn(
          duration: const Duration(milliseconds: 220),
        ).slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 16),
        _HomeMetaSection(user: user).animate(delay: const Duration(milliseconds: 120)).fadeIn(
          duration: const Duration(milliseconds: 240),
        ).slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 16),
        _HomeReadmeSection(
          user: user,
          profileReadme: profileState.profileReadme,
        ).animate(delay: const Duration(milliseconds: 180)).fadeIn(
          duration: const Duration(milliseconds: 260),
        ).slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.person_off_outlined,
      title: '未能找到用户消息',
      message: '请下拉刷新重试',
    );
  }
}

class _HomeHeaderCard extends StatelessWidget {
  final User user;
  final String joinDateText;
  final VoidCallback onOpenSettings;

  const _HomeHeaderCard({
    required this.user,
    required this.joinDateText,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'user_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  key: ValueKey(user.avatarUrl),
                  imageUrl: user.avatarUrl,
                  memCacheWidth: 128,
                  memCacheHeight: 128,
                  imageBuilder:
                      (context, imageProvider) => CircleAvatar(
                        radius: 32,
                        backgroundImage: imageProvider,
                      ),
                  placeholder:
                      (context, _) => CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                  errorWidget:
                      (context, _, __) => CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.person),
                      ),
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.login,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.login}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (joinDateText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          OctIcons.calendar_24,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            joinDateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: colorScheme.primaryContainer
              ),
              onPressed: onOpenSettings,
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickActions extends StatelessWidget {
  final int publicRepos;
  final int starredRepos;
  final VoidCallback onOpenRepos;
  final VoidCallback onOpenStarred;

  const _HomeQuickActions({
    required this.publicRepos,
    required this.starredRepos,
    required this.onOpenRepos,
    required this.onOpenStarred,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: OctIcons.repo_16,
            iconColor: Theme.of(context).colorScheme.primary,
            title: '仓库',
            value: '$publicRepos 个公开',
            onTap: onOpenRepos,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: OctIcons.star_fill_16,
            iconColor: Colors.amber.shade700,
            title: '星标',
            value: '$starredRepos 个已加载',
            onTap: onOpenStarred,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMetaSection extends StatelessWidget {
  final User user;

  const _HomeMetaSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasBio = user.bio != null && user.bio!.trim().isNotEmpty;
    final hasLocation = user.location != null && user.location!.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBio)
              Text(
                user.bio!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (hasBio) const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: OctIcons.people_16,
                  text: '${user.followers} followers',
                ),
                _MetaChip(
                  icon: Icons.person_outline,
                  text: '${user.following} following',
                ),
                if (hasLocation)
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    text: user.location!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeReadmeSection extends StatelessWidget {
  final User user;
  final String? profileReadme;

  const _HomeReadmeSection({required this.user, required this.profileReadme});

  @override
  Widget build(BuildContext context) {
    final hasReadme = profileReadme != null && profileReadme!.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              OctIcons.book_16,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Profile README',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOut,
          child:
              hasReadme
                  ? Card(
                    key: const ValueKey('readme_content'),
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: GitHubMarkdown(
                        data: profileReadme!,
                        owner: user.login,
                        repo: user.login,
                        selectable: true,
                      ),
                    ),
                  )
                  : Container(
                    key: const ValueKey('readme_empty'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '还没有个人主页仓库，快去添加吧~',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

class _HomeInitialLoadingView extends StatelessWidget {
  const _HomeInitialLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '正在同步 GitHub 数据...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '首次加载可能稍慢，请耐心等待...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 220)).slideY(
      begin: 0.04,
      end: 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}
