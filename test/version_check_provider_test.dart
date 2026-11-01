import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/models/release_info.dart';
import 'package:ghclient/pages/settings_page.dart';
import 'package:ghclient/services/github_service.dart';

void main() {
  group('isNewerVersion 语义化版本比对与边界', () {
    test('处理前导 v/V、构建号 +build 与多位数段比对', () {
      expect(isNewerVersion('v0.4.0', '0.3.3+10'), isTrue);
      expect(isNewerVersion('V0.10.0', '0.3.3'), isTrue);
      expect(isNewerVersion('v0.3.3', '0.3.3+10'), isFalse);
      expect(isNewerVersion('0.3.2', '0.3.3'), isFalse);
    });

    test('处理缺省 patch 段、预发布后缀与非法输入返回 null', () {
      expect(isNewerVersion('0.4', '0.3.9'), isTrue);
      expect(isNewerVersion('0.4.0', '0.4.0-beta.1'), isTrue);
      expect(isNewerVersion('0.4.0-beta.1', '0.4.0'), isFalse);
      expect(isNewerVersion('0.4.0-beta.2', '0.4.0-beta.1'), isTrue);
      expect(isNewerVersion('', '0.3.3'), isNull);
      expect(isNewerVersion('release-2024-01', '0.3.3'), isNull);
      expect(isNewerVersion('0.4.0', '...'), isNull);
    });

    test('ReleaseInfo.fromJson 在 html_url 缺失时回退默认 Releases 地址', () {
      final info = ReleaseInfo.fromJson({
        'tag_name': 'v0.5.0',
        'html_url': '',
        'body': '  新增版本检查功能  ',
      });
      expect(info.version, '0.5.0');
      expect(info.htmlUrl, ReleaseInfo.defaultReleasesUrl);
      expect(info.body, '新增版本检查功能');
    });
  });

  group('VersionCheckNotifier 状态流转与并发守卫', () {
    test('三态流转与运行中版本变化即时生效', () async {
      var localVersion = '0.3.3';
      ApiResult<ReleaseInfo> remoteResult = (null, null);

      final container = ProviderContainer.test(
        overrides: [
          readLocalVersionProvider.overrideWithValue(() async => localVersion),
          fetchLatestReleaseProvider.overrideWithValue(
            () async => remoteResult,
          ),
        ],
      );
      addTearDown(container.dispose);

      // 1. 尚无 Release (404 -> (null, null)) 时视为已是最新
      final firstState = await container
          .read(versionCheckProvider.notifier)
          .checkForUpdate();
      expect(firstState.status, VersionCheckStatus.upToDate);

      // 2. 远端发布 v0.4.0，再次检查立即识别为有新版本
      remoteResult = (
        ReleaseInfo.fromJson({
          'tag_name': 'v0.4.0',
          'html_url':
              'https://github.com/SunWithCat/github-client/releases/tag/v0.4.0',
          'body': '- 修复若干问题',
        }),
        null,
      );
      final secondState = await container
          .read(versionCheckProvider.notifier)
          .checkForUpdate();
      expect(secondState.status, VersionCheckStatus.updateAvailable);
      expect(secondState.latestRelease?.version, '0.4.0');

      // 3. 本地版本升级到 0.4.0 后，再次检查变为 upToDate
      localVersion = '0.4.0';
      final thirdState = await container
          .read(versionCheckProvider.notifier)
          .checkForUpdate();
      expect(thirdState.status, VersionCheckStatus.upToDate);
    });

    test('检查进行中并发重入不会重复发起网络请求', () async {
      final completer = Completer<ApiResult<ReleaseInfo>>();
      var fetchCount = 0;

      final container = ProviderContainer.test(
        overrides: [
          readLocalVersionProvider.overrideWithValue(() async => '0.3.3'),
          fetchLatestReleaseProvider.overrideWithValue(() {
            fetchCount++;
            return completer.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(versionCheckProvider.notifier);
      final firstCall = notifier.checkForUpdate();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(versionCheckProvider).isChecking, isTrue);

      // 并发重入调用
      final secondCall = await notifier.checkForUpdate();
      expect(secondCall.status, VersionCheckStatus.checking);
      expect(fetchCount, 1);

      completer.complete((
        ReleaseInfo.fromJson({'tag_name': 'v0.3.3'}),
        null,
      ));
      final finalState = await firstCall;
      expect(finalState.status, VersionCheckStatus.upToDate);
      expect(container.read(versionCheckProvider).isChecking, isFalse);
    });

    test('请求失败后恢复非检查态并支持安全重试', () async {
      var shouldFail = true;

      final container = ProviderContainer.test(
        overrides: [
          readLocalVersionProvider.overrideWithValue(() async => '0.3.3'),
          fetchLatestReleaseProvider.overrideWithValue(() async {
            if (shouldFail) {
              return (null, '网络连接不稳定 🌊');
            }
            return (
              ReleaseInfo.fromJson({
                'tag_name': 'v0.4.0',
                'body': 'Release notes',
              }),
              null,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(versionCheckProvider.notifier);
      final errorState = await notifier.checkForUpdate();
      expect(errorState.status, VersionCheckStatus.error);
      expect(errorState.errorMessage, '网络连接不稳定 🌊');
      expect(errorState.isChecking, isFalse);

      shouldFail = false;
      final retryState = await notifier.checkForUpdate();
      expect(retryState.status, VersionCheckStatus.updateAvailable);
      expect(retryState.latestRelease?.tagName, 'v0.4.0');
    });

    test('远端 tag 非语义化版本号时不得误报 upToDate，应进入 error 状态', () async {
      final container = ProviderContainer.test(
        overrides: [
          readLocalVersionProvider.overrideWithValue(() async => '0.3.3'),
          fetchLatestReleaseProvider.overrideWithValue(
            () async => (
              ReleaseInfo.fromJson({'tag_name': 'release-2024-01'}),
              null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container
          .read(versionCheckProvider.notifier)
          .checkForUpdate();
      expect(state.status, VersionCheckStatus.error);
      expect(state.errorMessage, '无法判断版本，请点击前往查看');
    });
  });

  testWidgets('SettingsPage 点击版本项在发现新版本时弹出更新对话框', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(
            User(
              login: 'SunWithCat',
              avatarUrl: 'https://example.com/avatar.png',
              name: 'SunWithCat',
              followers: 0,
              following: 0,
              publicRepos: 0,
              createdAt: '2024-01-01T00:00:00Z',
            ),
          ),
          appVersionProvider.overrideWithValue('0.3.3'),
          readLocalVersionProvider.overrideWithValue(() async => '0.3.3'),
          fetchLatestReleaseProvider.overrideWithValue(
            () async => (
              ReleaseInfo.fromJson({
                'tag_name': 'v0.4.0',
                'html_url':
                    'https://github.com/SunWithCat/github-client/releases/tag/v0.4.0',
                'body': '1. 接入真实版本检查',
              }),
              null,
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(find.text('版本'));
    await tester.pumpAndSettle();

    expect(find.text('发现新版本 v0.4.0'), findsOneWidget);
    expect(find.text('1. 接入真实版本检查'), findsOneWidget);
    expect(find.text('前往下载'), findsOneWidget);
  });

  testWidgets('SettingsPage 遇到非语义化版本 tag 时弹出无法判断版本提示而非目前已是最新版', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(
            User(
              login: 'SunWithCat',
              avatarUrl: 'https://example.com/avatar.png',
              name: 'SunWithCat',
              followers: 0,
              following: 0,
              publicRepos: 0,
              createdAt: '2024-01-01T00:00:00Z',
            ),
          ),
          appVersionProvider.overrideWithValue('0.3.3'),
          readLocalVersionProvider.overrideWithValue(() async => '0.3.3'),
          fetchLatestReleaseProvider.overrideWithValue(
            () async => (
              ReleaseInfo.fromJson({'tag_name': 'release-2024-01'}),
              null,
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(find.text('版本'));
    await tester.pumpAndSettle();

    expect(find.text('目前已是最新版~'), findsNothing);
    expect(find.text('无法判断版本，请点击前往查看'), findsOneWidget);
    expect(find.text('前往查看'), findsOneWidget);
  });
}
