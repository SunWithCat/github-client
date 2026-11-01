import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/core/app_identity.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/release_info.dart';
import 'package:ghclient/services/github_service.dart';

/// 语义化版本比对：
/// - 当 [remoteVersion] 严格大于 [localVersion] 时返回 `true`
/// - 当 [remoteVersion] 小于或等于 [localVersion] 时返回 `false`
/// - 当任一版本号无法按语义化版本解析时返回 `null`
bool? isNewerVersion(String remoteVersion, String localVersion) {
  final remoteParsed = _ParsedVersion.tryParse(remoteVersion);
  final localParsed = _ParsedVersion.tryParse(localVersion);
  if (remoteParsed == null || localParsed == null) {
    return null;
  }
  return remoteParsed.compareTo(localParsed) > 0;
}

class _ParsedVersion {
  final List<int> coreSegments;
  final List<String>? preReleaseSegments;

  const _ParsedVersion({
    required this.coreSegments,
    this.preReleaseSegments,
  });

  static _ParsedVersion? tryParse(String raw) {
    final normalized = normalizeVersion(raw);
    if (normalized.isEmpty) return null;

    final dashIndex = normalized.indexOf('-');
    final corePart = dashIndex == -1
        ? normalized
        : normalized.substring(0, dashIndex);
    final prePart = dashIndex == -1
        ? null
        : normalized.substring(dashIndex + 1).trim();

    if (corePart.isEmpty) return null;

    final rawSegments = corePart.split('.');
    final coreSegments = <int>[];
    for (final segment in rawSegments) {
      if (segment.isEmpty) return null;
      final value = int.tryParse(segment);
      if (value == null || value < 0) return null;
      coreSegments.add(value);
    }

    final preSegments = (prePart != null && prePart.isNotEmpty)
        ? prePart.split('.').where((s) => s.isNotEmpty).toList()
        : null;

    return _ParsedVersion(
      coreSegments: coreSegments,
      preReleaseSegments:
          (preSegments != null && preSegments.isNotEmpty) ? preSegments : null,
    );
  }

  int compareTo(_ParsedVersion other) {
    final maxLength = math.max(coreSegments.length, other.coreSegments.length);
    for (var i = 0; i < maxLength; i++) {
      final a = i < coreSegments.length ? coreSegments[i] : 0;
      final b = i < other.coreSegments.length ? other.coreSegments[i] : 0;
      if (a != b) {
        return a.compareTo(b);
      }
    }

    final aPre = preReleaseSegments;
    final bPre = other.preReleaseSegments;
    if (aPre == null && bPre == null) return 0;
    // 正式版 > 预发布版
    if (aPre == null) return 1;
    if (bPre == null) return -1;

    final minPreLength = math.min(aPre.length, bPre.length);
    for (var i = 0; i < minPreLength; i++) {
      final aSeg = aPre[i];
      final bSeg = bPre[i];
      if (aSeg == bSeg) continue;

      final aNum = int.tryParse(aSeg);
      final bNum = int.tryParse(bSeg);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      // 数字标识符优先级低于非数字标识符
      if (aNum != null) return -1;
      if (bNum != null) return 1;
      return aSeg.compareTo(bSeg);
    }
    return aPre.length.compareTo(bPre.length);
  }
}

enum VersionCheckStatus { idle, checking, upToDate, updateAvailable, error }

class VersionCheckState {
  final VersionCheckStatus status;
  final ReleaseInfo? latestRelease;
  final String? errorMessage;

  const VersionCheckState({
    this.status = VersionCheckStatus.idle,
    this.latestRelease,
    this.errorMessage,
  });

  bool get isChecking => status == VersionCheckStatus.checking;
}

typedef FetchLatestRelease = Future<ApiResult<ReleaseInfo>> Function();
typedef ReadLocalVersion = Future<String> Function();

final fetchLatestReleaseProvider = Provider<FetchLatestRelease>((ref) {
  return () {
    final token = ref.read(profileProvider).token;
    return ref.read(githubServiceProvider).getLatestRelease(
      AppIdentity.repoOwner,
      AppIdentity.repoName,
      token: token,
    );
  };
});

final readLocalVersionProvider = Provider<ReadLocalVersion>((ref) {
  return () async {
    final info = await ref.read(packageInfoProvider.future);
    return info.version;
  };
});

final versionCheckProvider =
    NotifierProvider<VersionCheckNotifier, VersionCheckState>(
      VersionCheckNotifier.new,
    );

class VersionCheckNotifier extends Notifier<VersionCheckState> {
  @override
  VersionCheckState build() {
    return const VersionCheckState();
  }

  /// 执行一次版本检查，若当前正在检查中则忽略重入调用
  Future<VersionCheckState> checkForUpdate() async {
    if (state.isChecking) return state;

    state = const VersionCheckState(status: VersionCheckStatus.checking);

    try {
      final localVersion = await ref.read(readLocalVersionProvider)();
      final (release, error) = await ref.read(fetchLatestReleaseProvider)();

      if (error != null) {
        state = VersionCheckState(
          status: VersionCheckStatus.error,
          errorMessage: error,
        );
        return state;
      }

      if (release == null) {
        state = const VersionCheckState(status: VersionCheckStatus.upToDate);
        return state;
      }

      final newer = isNewerVersion(release.tagName, localVersion);
      if (newer == null) {
        state = VersionCheckState(
          status: VersionCheckStatus.error,
          latestRelease: release,
          errorMessage: '无法判断版本，请点击前往查看',
        );
        return state;
      }

      if (newer) {
        state = VersionCheckState(
          status: VersionCheckStatus.updateAvailable,
          latestRelease: release,
        );
        return state;
      }

      state = VersionCheckState(
        status: VersionCheckStatus.upToDate,
        latestRelease: release,
      );
      return state;
    } catch (e) {
      state = VersionCheckState(
        status: VersionCheckStatus.error,
        errorMessage: '检查更新失败: $e',
      );
      return state;
    }
  }
}
