import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/number_formatter.dart';
import 'package:ghclient/common/utils/language_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:ghclient/common/widgets/scale_wrapper.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/router/app_router.dart';
import 'package:ghclient/theme/theme.dart';

/// 仓库列表项组件：使用 ConsumerWidget
class RepoItem extends ConsumerWidget {
  final Repo repo;
  final bool showVisibilityBadge;
  const RepoItem({
    super.key,
    required this.repo,
    this.showVisibilityBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final semanticColors = theme.semanticColors;

    return ScaleWrapper(
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final token = ref.read(tokenProvider);
              if (token != null) {
                context.push(
                  '/repo',
                  extra: RepoDetailArgs(repo: repo, token: token),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
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
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                        color: semanticColors.star,
                      ),
                      const SizedBox(width: 4),
                      Text(NumberFormatter.formatNumber(repo.starCount)),
                      const SizedBox(width: 16),
                      Icon(
                        OctIcons.repo_forked_16,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(NumberFormatter.formatNumber(repo.forkCount)),
                    ],
                  ),
                ],
              ),
            ),
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
    final background = isPrivate
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final border = isPrivate
        ? colorScheme.primary.withValues(alpha: 0.35)
        : colorScheme.outlineVariant;
    final foreground = isPrivate
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minWidth: 56, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border, width: 1.0),
        ),
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
