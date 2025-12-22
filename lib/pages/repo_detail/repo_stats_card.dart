import 'package:flutter/material.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/stat_item.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:url_launcher/url_launcher.dart';

class RepoStatsCard extends StatelessWidget {
  /// 仓库数据
  final Repo repo;

  const RepoStatsCard({
    super.key,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 渐变背景颜色
    final gradientColors = isDark
        ? [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ]
        : [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.blueGrey.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
              ),
            
            // 统计信息行
            _buildStatsRow(context, isDark),
            
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            context,
            icon: OctIcons.star_fill_16,
            value: StatItem.formatNumber(repo.starCount),
            label: '星标',
            iconColor: Colors.amber.shade600,
          ),
          _buildDivider(isDark),
          _buildStatColumn(
            context,
            icon: OctIcons.repo_forked_16,
            value: StatItem.formatNumber(repo.forkCount),
            label: '分支',
            iconColor: isDark ? Colors.teal.shade300 : Colors.teal.shade600,
          ),
          if (repo.language != null) ...[
            _buildDivider(isDark),
            _buildStatColumn(
              context,
              icon: OctIcons.code_16,
              value: repo.language!,
              label: '语言',
              iconColor: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
            ),
          ],
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
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 构建分隔线
  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark 
          ? Colors.grey.shade700
          : Colors.grey.shade300,
    );
  }

  /// 构建 GitHub 链接按钮
  Widget _buildGitHubButton(BuildContext context, bool isDark) {
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
          side: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          OctIcons.mark_github_16,
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
        label: Text(
          '在 GitHub 上查看',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
