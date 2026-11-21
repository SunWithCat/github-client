import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:ghclient/common/widgets/github_markdown.dart';
import 'package:ghclient/core/repo_languages_provider.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/repo_stats_card.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final Repo repo;
  final String token;
  final String? readmeContent;
  final Future<void> Function() onRefresh;
  final String branch;

  const OverviewTab({
    super.key,
    required this.repo,
    required this.token,
    this.readmeContent,
    required this.onRefresh,
    required this.branch,
  });

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = widget.repo;
    final readmeContent = widget.readmeContent;
    final languagesProvider = repoLanguagesProvider((
      owner: repo.owner,
      repoName: repo.name,
      token: widget.token,
    ));
    final languages = ref.watch(languagesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          widget.onRefresh(),
          ref
              .refresh(languagesProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: RepoStatsCard(
                repo: repo,
                languages: languages,
                onRetryLanguages: () => ref.invalidate(languagesProvider),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: readmeContent != null
                ? _buildReadmeSliver(context, readmeContent)
                : SliverToBoxAdapter(child: _buildEmptyReadmeCard(context)),
          ),
        ],
      ),
    );
  }

  /// 构建 README 卡片顶部标题栏
  Widget _buildReadmeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            OctIcons.book_16,
            size: 18,
            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'README',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? colorScheme.onSurface : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建支持 Sliver 按需懒加载的 README 区域
  Widget _buildReadmeSliver(BuildContext context, String readmeContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return DecoratedSliver(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
          width: 1,
        ),
      ),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: _buildReadmeHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: GitHubMarkdown(
                data: readmeContent,
                owner: widget.repo.owner,
                repo: widget.repo.name,
                branch: widget.branch,
                selectable: false,
                renderMode: RenderMode.sliverList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空 README 状态卡片
  Widget _buildEmptyReadmeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadmeHeader(context),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    OctIcons.file_16,
                    size: 32,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此仓库没有 README 文件',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
