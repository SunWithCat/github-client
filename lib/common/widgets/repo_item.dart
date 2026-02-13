import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/router/app_router.dart';

/// 仓库列表项组件：使用 ConsumerWidget
class RepoItem extends ConsumerWidget {
  final Repo repo;
  final bool showVisibilityBadge;
  const RepoItem({
    super.key,
    required this.repo,
    this.showVisibilityBadge = false,
  });

  Color getLanguageColor(String? language) {
    if (language == null) return Colors.grey;
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB); // Dart
      case 'java':
        return const Color(0xFFB07219); // Java
      case 'javascript':
        return const Color(0xFFF1E05A); // JavaScript
      case 'typescript':
        return const Color(0xFF3178c6); // TypeScript
      case 'html':
        return const Color(0xFFe34c26); // HTML
      case 'css':
        return const Color(0xFF563d7c); // CSS
      case 'vue':
        return const Color(0xFF41b883); // Vue
      case 'c++':
        return const Color(0xFFf34b7d); // C++
      case 'c':
        return const Color(0xFF555555); // C
      case 'c#':
        return const Color(0xFF178600); // C#
      case 'python':
        return const Color(0xFF3572A5); // Python
      case 'php':
        return const Color(0xFF4F5D95); // PHP
      case 'ruby':
        return const Color(0xFF701516); // Ruby
      case 'go':
        return const Color(0xFF00ADD8); // Go
      case 'rust':
        return const Color(0xFFdea584); // Rust
      case 'swift':
        return const Color(0xFFF05138); // Swift
      case 'kotlin':
        return const Color(0xFFA97BFF); // Kotlin
      case 'scala':
        return const Color(0xFFc22d40); // Scala
      case 'shell':
        return const Color(0xFF89E051); // Shell
      case 'dockerfile':
        return const Color(0xFF384D54); // Dockerfile
      default:
        return Colors.grey.shade600;
    }
  }

  // 格式化数字显示
  String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shadowColor: theme.cardTheme.shadowColor,
      child: InkWell(
        onTap: () {
          // 🔄 使用 ref.read 获取 token
          final token = ref.read(tokenProvider);
          if (token != null) {
            context.push(
              '/repo',
              extra: RepoDetailArgs(repo: repo, token: token),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    OctIcons.repo_16,
                    size: 16,
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            theme.brightness == Brightness.light
                                ? Color(0xFF0366D6)
                                : Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showVisibilityBadge) ...[
                    const SizedBox(width: 8),
                    _VisibilityBadge(isPrivate: repo.isPrivate),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (repo.description != null && repo.description!.isNotEmpty)
                Text(
                  repo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (repo.language != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: getLanguageColor(repo.language),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(repo.language!),
                    const SizedBox(width: 16),
                  ],
                  Icon(
                    OctIcons.star_fill_16,
                    size: 16,
                    color: Colors.yellow.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(formatNumber(repo.starCount)),
                  const SizedBox(width: 16),
                  Icon(
                    OctIcons.repo_forked_16,
                    size: 16,
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(formatNumber(repo.forkCount)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final bool isPrivate;

  const _VisibilityBadge({required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isPrivate
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    final border =
        isPrivate
            ? colorScheme.primary.withValues(alpha: 0.35)
            : colorScheme.outlineVariant.withValues(alpha: 0.65);
    final foreground =
        isPrivate
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minWidth: 56, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          isPrivate ? 'Private' : 'Public',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
