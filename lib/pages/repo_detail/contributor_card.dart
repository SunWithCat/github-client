import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ghclient/pages/repo_detail/contribution_bar.dart';

class ContributorCard extends StatelessWidget {
  final Map<String, dynamic> contributor;

  /// 项目总贡献数（用于计算百分比）
  final int totalContributions;

  /// 点击回调
  final VoidCallback? onTap;

  const ContributorCard({
    super.key,
    required this.contributor,
    required this.totalContributions,
    this.onTap,
  });

  /// 获取头像 URL
  String get avatarUrl => contributor['avatar_url']?.toString() ?? '';

  /// 获取用户名
  String get login => contributor['login']?.toString() ?? '';

  /// 获取贡献数
  int get contributions => contributor['contributions'] ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 头像
              _buildAvatar(isDark),
              const SizedBox(width: 12),
              // 用户信息和进度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户名
                    Text(
                      login,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 贡献数
                    Text(
                      '$contributions 次贡献',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 贡献度进度条
                    ContributionBar(
                      contributions: contributions,
                      totalContributions: totalContributions,
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

  /// 构建头像组件
  Widget _buildAvatar(bool isDark) {
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        child: Icon(
          Icons.person,
          size: 24,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 24,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        child: Icon(
          Icons.person,
          size: 24,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
