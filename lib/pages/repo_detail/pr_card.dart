import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:ghclient/common/utils/date_formatter.dart';
import 'package:ghclient/pages/repo_detail/issue_label.dart';

class PrCard extends StatelessWidget {
  final Map<String, dynamic> pr;
  final VoidCallback? onTap;
  const PrCard({super.key, required this.pr, this.onTap});

  // 判断 PR 状态
  String get _state {
    if (pr['merged_at'] != null) return 'merged';
    return pr['state']?.toString() ?? 'open';
  }

  IconData get _statusIcon => switch (_state) {
    'merged' => OctIcons.git_merge_16,
    'closed' => OctIcons.git_pull_request_closed_16,
    _ => OctIcons.git_pull_request_16,
  };

  Color get _statusColor => switch (_state) {
    'merged' => Colors.purple,
    'closed' => Colors.red,
    _ => Colors.green,
  };

  String get _title => pr['title']?.toString() ?? '';
  int get _number => pr['number'] ?? 0;

  String get _authorLogin {
    final user = pr['user'];
    if (user is Map<String, dynamic>) return user['login']?.toString() ?? '';
    return '';
  }

  String get _headRef => pr['head']?['ref']?.toString() ?? '';
  String get _baseRef => pr['base']?['ref']?.toString() ?? '';
  String get _createdAt => pr['created_at']?.toString() ?? '';

  List<Map<String, dynamic>> get _labels {
    final labelList = pr['labels'];
    if (labelList is List) {
      return labelList.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(_statusIcon, color: _statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 元信息行：编号 · 作者 · 时间
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                children: [
                  Text(
                    '#$_number',
                    style: TextStyle(
                      fontSize: 13,
                      color: subTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _dot(isDark),
                  const SizedBox(width: 8),
                  Text(
                    _authorLogin,
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),
                  const SizedBox(width: 8),
                  _dot(isDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormatter.relative(_createdAt),
                      style: TextStyle(fontSize: 13, color: subTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 分支信息行：head → base
            if (_headRef.isNotEmpty && _baseRef.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(OctIcons.git_branch_16, size: 12, color: subTextColor),
                    const SizedBox(width: 4),
                    Text(
                      '$_headRef → $_baseRef',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            // 标签
            if (_labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _labels.map((label) {
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
    );
  }

  Widget _dot(bool isDark) => Container(
    width: 3,
    height: 3,
    decoration: BoxDecoration(
      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
      shape: BoxShape.circle,
    ),
  );
}
