import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ghclient/common/utils/date_formatter.dart';

class CommitCard extends StatefulWidget {
  final Map<String, dynamic> commit;

  final VoidCallback? onTap;

  const CommitCard({
    super.key,
    required this.commit,
    this.onTap,
  });

  @override
  State<CommitCard> createState() => _CommitCardState();
}

class _CommitCardState extends State<CommitCard> {
  /// 是否展开完整消息
  bool _isExpanded = false;

  /// 获取 commit 信息对象
  Map<String, dynamic> get commitInfo {
    final info = widget.commit['commit'];
    if (info is Map<String, dynamic>) {
      return info;
    }
    return {};
  }
  Map<String, dynamic> get authorInfo {
    final author = commitInfo['author'];
    if (author is Map<String, dynamic>) {
      return author;
    }
    return {};
  }

  Map<String, dynamic> get committerInfo {
    final committer = widget.commit['author'];
    if (committer is Map<String, dynamic>) {
      return committer;
    }
    return {};
  }

  /// 获取提交者头像 URL
  String? get avatarUrl => committerInfo['avatar_url']?.toString();

  /// 获取完整的提交消息
  String get fullMessage => commitInfo['message']?.toString() ?? '';

  /// 获取第一行消息（用于截断显示）
  String get firstLineMessage {
    final lines = fullMessage.split('\n');
    return lines.isNotEmpty ? lines.first : '';
  }

  bool get needsTruncation {
    return firstLineMessage.length > 80 || fullMessage.contains('\n');
  }

  /// 获取截断后的消息
  String get truncatedMessage {
    if (firstLineMessage.length > 80) {
      return '${firstLineMessage.substring(0, 77)}...';
    }
    return firstLineMessage;
  }

  /// 获取显示的消息
  String get displayMessage {
    if (_isExpanded) {
      return fullMessage;
    }
    return needsTruncation ? truncatedMessage : firstLineMessage;
  }

  /// 获取作者名称
  String get authorName {
    // 优先使用 committer 的 login，否则使用 author 的 name
    return committerInfo['login']?.toString() ?? 
           authorInfo['name']?.toString() ?? 
           '';
  }

  /// 获取提交日期
  String get commitDate => authorInfo['date']?.toString() ?? '';

  /// 获取 SHA 的短版本（前 7 位）
  String get shortSha {
    final sha = widget.commit['sha']?.toString() ?? '';
    return sha.length >= 7 ? sha.substring(0, 7) : sha;
  }

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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 提交者头像
                  _buildAvatar(isDark),
                  const SizedBox(width: 12),
                  // 提交消息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                        // 展开/收起按钮
                        if (needsTruncation) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Text(
                              _isExpanded ? '收起' : '展开',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.blue.shade300 
                                    : Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    // 作者名称
                    Icon(
                      OctIcons.person_16,
                      size: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      authorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // SHA
                    Icon(
                      OctIcons.git_commit_16,
                      size: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shortSha,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 提交时间
                    Icon(
                      OctIcons.clock_16,
                      size: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormatter.relative(commitDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  /// 构建头像组件
  Widget _buildAvatar(bool isDark) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: 36,
          height: 36,
          memCacheWidth: 72, // 36 * 2 (for high DPI)
          memCacheHeight: 72,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(isDark),
        ),
      );
    }
    return _buildDefaultAvatar(isDark);
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar(bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        OctIcons.person_16,
        size: 20,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
    );
  }
}
