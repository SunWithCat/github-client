import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/number_formatter.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/repo_languages_section.dart';
import 'package:ghclient/theme/theme.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:url_launcher/url_launcher.dart';

class RepoStatsCard extends StatelessWidget {
  /// 仓库数据
  final Repo repo;
  final AsyncValue<Map<String, int>> languages;
  final VoidCallback onRetryLanguages;

  const RepoStatsCard({
    super.key,
    required this.repo,
    required this.languages,
    required this.onRetryLanguages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // 浅色保留清透微蓝渐变，深色保持克制的石板灰阶过渡
    final gradientColors = [
      colorScheme.surface,
      Color.lerp(
        colorScheme.surface,
        isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primaryContainer,
        isDark ? 0.55 : 0.38,
      )!,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 仓库描述
            if (repo.description != null && repo.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  repo.description!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

            // 统计信息行
            _buildStatsRow(context, isDark),

            const SizedBox(height: 20),

            // 语言统计
            RepoLanguagesSection(
              languages: languages,
              onRetry: onRetryLanguages,
            ),

            const SizedBox(height: 20),

            // GitHub 链接按钮
            _buildGitHubButton(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息行
  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = theme.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            context,
            icon: OctIcons.star_fill_16,
            value: NumberFormatter.formatNumber(repo.starCount),
            label: '星标',
            iconColor: semanticColors.star,
          ),
          _buildDivider(context),
          _buildStatColumn(
            context,
            icon: OctIcons.repo_forked_16,
            value: NumberFormatter.formatNumber(repo.forkCount),
            label: '分支',
            iconColor: semanticColors.fork,
          ),
        ],
      ),
    );
  }

  /// 构建单个统计列
  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建分隔线
  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  /// 构建 GitHub 链接按钮
  Widget _buildGitHubButton(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final url = Uri.parse(
            'https://github.com/${repo.owner}/${repo.name}',
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.5 : 0.45,
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(OctIcons.mark_github_16, color: colorScheme.onSurface),
        label: Text(
          '在 GitHub 上查看',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
