import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:ghclient/common/widgets/github_markdown.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_detail/repo_stats_card.dart';

class OverviewTab extends StatefulWidget {
  final Repo repo;
  final String? readmeContent;
  final Future<void> Function() onRefresh;

  const OverviewTab({
    super.key,
    required this.repo,
    this.readmeContent,
    required this.onRefresh,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 控制 README 是否展开
  bool _isReadmeExpanded = false;
  // 默认显示的字符数限制
  static const int _collapsedCharLimit = 2000;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = widget.repo;
    final readmeContent = widget.readmeContent;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用新的 RepoStatsCard 组件
            RepoStatsCard(repo: repo),

            const SizedBox(height: 16),
            if (readmeContent != null) ...[
              _buildReadmeSection(context, readmeContent),
            ] else
              _buildEmptyReadmeCard(context),
          ],
        ),
      ),
    );
  }

  /// 获取截断后的 README 内容
  String _getTruncatedReadme(String? content) {
    if (content == null || content.length <= _collapsedCharLimit) {
      return content ?? '';
    }
    if (_isReadmeExpanded) {
      return content;
    }
    // 在字符限制附近找一个换行符截断，避免截断在单词中间
    int cutIndex = content.lastIndexOf('\n', _collapsedCharLimit);
    if (cutIndex < _collapsedCharLimit * 0.7) {
      cutIndex = _collapsedCharLimit;
    }
    return content.substring(0, cutIndex);
  }

  /// 判断 README 是否需要展开按钮
  bool _needsExpansion(String? content) {
    return content != null && content.length > _collapsedCharLimit;
  }

  /// 构建 README 区域，包含清晰的 section header 和适当间距
  Widget _buildReadmeSection(BuildContext context, String? readmeContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final needsExpansion = _needsExpansion(readmeContent);
    final displayContent = _getTruncatedReadme(readmeContent);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  OctIcons.book_16,
                  size: 18,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'README',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // README Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: GitHubMarkdown(
                  data: displayContent,
                  owner: widget.repo.owner,
                  repo: widget.repo.name,
                  branch: widget.repo.defaultBranch ?? 'main',
                  selectable: false,
                ),
              ),
            ),
          ),
          // 展开/收起按钮
          if (needsExpansion)
            InkWell(
              onTap: () {
                setState(() {
                  _isReadmeExpanded = !_isReadmeExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800.withValues(alpha: 0.3)
                      : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isReadmeExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: isDark
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isReadmeExpanded ? '收起' : '展开全部',
                      style: TextStyle(
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
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

  /// 构建空 README 状态卡片
  Widget _buildEmptyReadmeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  OctIcons.book_16,
                  size: 18,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'README',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Empty State
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
