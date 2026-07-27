import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/core/device_auth_provider.dart';
import 'package:ghclient/models/device_auth.dart';
import 'package:ghclient/services/github_auth_service.dart';

void main() {
  test('等待授权时遵守初始轮询间隔，slow_down 后增加五秒', () async {
    final gateway = _FakeGateway(
      tokenResults: const [
        DeviceTokenAuthorizationPending(),
        DeviceTokenSlowDown(),
      ],
    );
    final scheduler = _FakeTimerFactory();
    final container = _container(gateway, scheduler);
    addTearDown(container.dispose);

    await container.read(deviceAuthProvider.notifier).start();

    expect(container.read(deviceAuthProvider).userCode, 'ABCD-1234');
    expect(scheduler.delays, [const Duration(seconds: 5)]);
    expect(gateway.pollCount, 0);

    scheduler.runNext();
    await _flush();
    expect(gateway.pollCount, 1);
    expect(scheduler.delays.last, const Duration(seconds: 5));

    scheduler.runNext();
    await _flush();
    expect(gateway.pollCount, 2);
    expect(scheduler.delays.last, const Duration(seconds: 10));
  });

  test('取得 token 后只验证一次用户并回到空闲状态', () async {
    final gateway = _FakeGateway(
      tokenResults: const [
        DeviceTokenSuccess(
          accessToken: 'access-token',
          tokenType: 'bearer',
          scope: '',
        ),
      ],
    );
    final scheduler = _FakeTimerFactory();
    final tokens = <String>[];
    final container = _container(
      gateway,
      scheduler,
      completeLogin: (token) async {
        tokens.add(token);
        return true;
      },
    );
    addTearDown(container.dispose);

    await container.read(deviceAuthProvider.notifier).start();
    scheduler.runNext();
    await _flush();

    expect(tokens, ['access-token']);
    expect(container.read(deviceAuthProvider).phase, DeviceAuthPhase.idle);
  });

  test('取消后忽略迟到的 token 响应', () async {
    final tokenResponse = Completer<DeviceTokenResult>();
    final gateway = _FakeGateway(pendingTokenResponse: tokenResponse);
    final scheduler = _FakeTimerFactory();
    var loginCount = 0;
    final container = _container(
      gateway,
      scheduler,
      completeLogin: (_) async {
        loginCount++;
        return true;
      },
    );
    addTearDown(container.dispose);

    await container.read(deviceAuthProvider.notifier).start();
    scheduler.runNext();
    await _flush();
    container.read(deviceAuthProvider.notifier).cancel();
    tokenResponse.complete(
      const DeviceTokenSuccess(
        accessToken: 'late-token',
        tokenType: 'bearer',
        scope: '',
      ),
    );
    await _flush();

    expect(loginCount, 0);
    expect(container.read(deviceAuthProvider).phase, DeviceAuthPhase.idle);
  });

  test('拒绝和过期都会停止轮询并允许重新登录', () async {
    for (final testCase in <(DeviceTokenResult, DeviceAuthPhase)>[
      (const DeviceTokenAccessDenied(), DeviceAuthPhase.denied),
      (const DeviceTokenExpired(), DeviceAuthPhase.expired),
    ]) {
      final gateway = _FakeGateway(tokenResults: [testCase.$1]);
      final scheduler = _FakeTimerFactory();
      final container = _container(gateway, scheduler);

      await container.read(deviceAuthProvider.notifier).start();
      scheduler.runNext();
      await _flush();

      expect(container.read(deviceAuthProvider).phase, testCase.$2);
      expect(scheduler.activeCount, 0);
      container.dispose();
    }
  });
}

ProviderContainer _container(
  GithubAuthGateway gateway,
  _FakeTimerFactory scheduler, {
  CompleteDeviceLogin? completeLogin,
}) {
  return ProviderContainer.test(
    overrides: [
      githubAuthConfigProvider.overrideWithValue((
        clientId: 'public-client-id',
        scope: '',
      )),
      githubAuthGatewayProvider.overrideWithValue(gateway),
      deviceAuthTimerFactoryProvider.overrideWithValue(scheduler.create),
      completeDeviceLoginProvider.overrideWithValue(
        completeLogin ?? (_) async => true,
      ),
    ],
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeGateway implements GithubAuthGateway {
  _FakeGateway({this.tokenResults = const [], this.pendingTokenResponse});

  final List<DeviceTokenResult> tokenResults;
  final Completer<DeviceTokenResult>? pendingTokenResponse;
  int pollCount = 0;

  @override
  Future<DeviceCodeResult> requestDeviceCode() async {
    return DeviceCodeSuccess(
      DeviceAuthorization(
        deviceCode: 'device-code',
        userCode: 'ABCD-1234',
        verificationUri: Uri.https('github.com', '/login/device'),
        expiresIn: Duration(minutes: 15),
        interval: Duration(seconds: 5),
      ),
    );
  }

  @override
  Future<DeviceTokenResult> pollToken(String deviceCode) {
    pollCount++;
    if (pendingTokenResponse != null) return pendingTokenResponse!.future;
    return Future.value(tokenResults[pollCount - 1]);
  }
}

class _FakeTimerFactory {
  final List<Duration> delays = [];
  final List<_FakeTimer> _timers = [];

  int get activeCount => _timers.where((timer) => timer.isActive).length;

  Timer create(Duration delay, void Function() callback) {
    delays.add(delay);
    final timer = _FakeTimer(callback);
    _timers.add(timer);
    return timer;
  }

  void runNext() {
    _timers.firstWhere((timer) => timer.isActive).run();
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _isActive ? 0 : 1;

  @override
  void cancel() {
    _isActive = false;
  }

  void run() {
    if (!_isActive) return;
    _isActive = false;
    _callback();
  }
}
