import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:ghclient/common/utils/date_formatter.dart';
import 'package:ghclient/pages/repo_detail/issue_label.dart';
import 'package:ghclient/theme/theme.dart';

class IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;

  final VoidCallback? onTap;

  const IssueCard({super.key, required this.issue, this.onTap});

  /// 获取 Issue 状态
  bool get isOpen => issue['state'] == 'open';

  /// 获取状态图标
  IconData get statusIcon =>
      isOpen ? OctIcons.issue_opened_16 : OctIcons.issue_closed_16;

  /// 获取状态颜色
  Color _statusColor(AppSemanticColors semantic) =>
      isOpen ? semantic.open : semantic.merged;

  /// 获取 Issue 标题
  String get title => issue['title']?.toString() ?? '';

  /// 获取 Issue 编号
  int get number => issue['number'] ?? 0;

  /// 获取作者用户名
  String get authorLogin {
    final user = issue['user'];
    if (user is Map<String, dynamic>) {
      return user['login']?.toString() ?? '';
    }
    return '';
  }

  /// 获取创建时间
  String get createdAt => issue['created_at']?.toString() ?? '';

  /// 获取标签列表
  List<Map<String, dynamic>> get labels {
    final labelList = issue['labels'];
    if (labelList is List) {
      return labelList.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subTextColor = colorScheme.onSurfaceVariant;
    final dotColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.65);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 状态图标
                  Container(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      statusIcon,
                      color: _statusColor(theme.semanticColors),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 标题
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    // Issue 编号
                    Text(
                      '#$number',
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 分隔点
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 作者
                    Text(
                      authorLogin,
                      style: TextStyle(fontSize: 13, color: subTextColor),
                    ),
                    const SizedBox(width: 8),
                    // 分隔点
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 创建时间（相对时间）
                    Expanded(
                      child: Text(
                        DateFormatter.relative(createdAt),
                        style: TextStyle(fontSize: 13, color: subTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: labels.map((label) {
                      return IssueLabel(
                        name: label['name']?.toString() ?? '',
                        color: label['color']?.toString() ?? 'cccccc',
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
