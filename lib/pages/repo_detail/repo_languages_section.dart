import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/language_colors.dart';

/// 仓库语言占比百分比展示组件
class RepoLanguagesSection extends StatelessWidget {
  final AsyncValue<Map<String, int>> languages;
  final VoidCallback onRetry;

  const RepoLanguagesSection({
    super.key,
    required this.languages,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '语言',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        languages.when(
          skipLoadingOnRefresh: languages.hasValue && !languages.hasError,
          skipError: false,
          data: (data) => _buildDistribution(context, data),
          loading: () => const LinearProgressIndicator(
            minHeight: 8,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            semanticsLabel: '正在加载语言统计',
          ),
          error: (_, _) => Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('语言统计加载失败', style: theme.textTheme.bodySmall),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(OctIcons.sync_16, size: 16),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistribution(BuildContext context, Map<String, int> data) {
    final theme = Theme.of(context);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    if (total == 0) {
      return Text('暂无语言统计', style: theme.textTheme.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final entry in entries)
                  Expanded(
                    flex: entry.value,
                    child: Tooltip(
                      message:
                          '${entry.key} ${_percentage(entry.value, total)}',
                      child: ColoredBox(
                        key: ValueKey('language-segment-${entry.key}'),
                        color: getLanguageColor(entry.key),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final entry in entries)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: getLanguageColor(entry.key),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _percentage(entry.value, total),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _percentage(int bytes, int total) {
    final percentage = bytes / total * 100;
    return percentage < 0.1 ? '<0.1%' : '${percentage.toStringAsFixed(1)}%';
  }
}
