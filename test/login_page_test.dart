import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/core/device_auth_provider.dart';
import 'package:ghclient/pages/login_page.dart';

void main() {
  testWidgets('空闲状态点击按钮会开始 Device Flow', (tester) async {
    final notifier = _FakeDeviceAuthNotifier(const DeviceAuthState());
    await tester.pumpWidget(_app(notifier));

    await tester.tap(find.byKey(const ValueKey('device_auth_start')));
    await tester.pump();

    expect(notifier.startCount, 1);
  });

  testWidgets('等待授权时显示验证码并打开 GitHub 验证页', (tester) async {
    final notifier = _FakeDeviceAuthNotifier(
      DeviceAuthState(
        phase: DeviceAuthPhase.waitingAuthorization,
        userCode: 'ABCD-1234',
        verificationUri: Uri.https('github.com', '/login/device'),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      ),
    );
    Uri? openedUri;
    await tester.pumpWidget(
      _app(
        notifier,
        launcher: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );

    expect(find.text('ABCD-1234'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('device_auth_open_github')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(openedUri, Uri.https('github.com', '/login/device'));
  });

  testWidgets('失败状态允许重新发起登录', (tester) async {
    final notifier = _FakeDeviceAuthNotifier(
      const DeviceAuthState(phase: DeviceAuthPhase.failure, message: '认证失败'),
    );
    await tester.pumpWidget(_app(notifier));

    expect(find.text('认证失败'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('device_auth_retry')));
    await tester.pump();

    expect(notifier.startCount, 1);
  });
}

Widget _app(_FakeDeviceAuthNotifier notifier, {ExternalUrlLauncher? launcher}) {
  return ProviderScope(
    overrides: [
      deviceAuthProvider.overrideWith(() => notifier),
      externalUrlLauncherProvider.overrideWithValue(
        launcher ?? (_) async => true,
      ),
      clipboardWriterProvider.overrideWithValue((_) async {}),
    ],
    child: const MaterialApp(home: LoginPage()),
  );
}

class _FakeDeviceAuthNotifier extends DeviceAuthNotifier {
  _FakeDeviceAuthNotifier(this.initialState);

  final DeviceAuthState initialState;
  int startCount = 0;

  @override
  DeviceAuthState build() => initialState;

  @override
  Future<void> start() async {
    startCount++;
  }

  @override
  void cancel() {
    state = const DeviceAuthState();
  }
}
