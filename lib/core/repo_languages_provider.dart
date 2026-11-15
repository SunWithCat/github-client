import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/core/providers.dart';

typedef RepoLanguagesRequest = ({String owner, String repoName, String token});

/// 仓库语言统计的唯一状态源，按仓库和登录凭据区分不同请求
final repoLanguagesProvider = FutureProvider.autoDispose
    .family<Map<String, int>, RepoLanguagesRequest>(
      (ref, request) async {
        final (languages, error) = await ref
            .watch(githubServiceProvider)
            .getLanguages(request.owner, request.repoName, request.token);
        if (error != null) throw Exception(error);
        return Map<String, int>.unmodifiable({
          for (final entry in (languages ?? <String, int>{}).entries)
            if (entry.key.trim().isNotEmpty && entry.value > 0)
              entry.key: entry.value,
        });
      },
      // 避免失败时连续请求，交由界面上的重试或下拉刷新
      retry: (_, _) => null,
    );
