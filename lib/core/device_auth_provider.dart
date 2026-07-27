import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/config.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/device_auth.dart';
import 'package:ghclient/services/github_auth_service.dart';

// 认证状态
enum DeviceAuthPhase {
  idle, // 未开始，或已完成认证
  requestingCode, // 正在请求验证码
  waitingAuthorization, // 等待授权
  loadingProfile, // 验证身份
  denied, // 拒绝授权
  expired, // 验证码已过期
  failure, // 登录失败
}

class DeviceAuthState {
  const DeviceAuthState({
    this.phase = DeviceAuthPhase.idle,
    this.userCode,
    this.verificationUri,
    this.expiresAt,
    this.message,
  });

  final DeviceAuthPhase phase;
  final String? userCode;
  final Uri? verificationUri;
  final DateTime? expiresAt;
  final String? message;

  // 是否正在进行认证流程
  bool get isActive =>
      phase == DeviceAuthPhase.requestingCode ||
      phase == DeviceAuthPhase.waitingAuthorization ||
      phase == DeviceAuthPhase.loadingProfile;
}

typedef CompleteDeviceLogin = Future<bool> Function(String token);
typedef DeviceAuthTimerFactory =
    Timer Function(Duration delay, void Function() callback);

typedef GithubAuthConfig = ({String clientId, String scope});

final githubAuthConfigProvider = Provider<GithubAuthConfig>((ref) {
  return (
    clientId: AppConfig.githubClientId,
    scope: AppConfig.githubOAuthScopes,
  );
});

final githubAuthGatewayProvider = Provider<GithubAuthGateway>((ref) {
  final config = ref.watch(githubAuthConfigProvider);
  return GithubAuthService(clientId: config.clientId, scope: config.scope);
});

final completeDeviceLoginProvider = Provider<CompleteDeviceLogin>((ref) {
  return ref.read(profileProvider.notifier).login;
});

final currentTimeProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final deviceAuthTimerFactoryProvider = Provider<DeviceAuthTimerFactory>((ref) {
  return (delay, callback) => Timer(delay, callback);
});

final deviceAuthProvider =
    NotifierProvider<DeviceAuthNotifier, DeviceAuthState>(
      DeviceAuthNotifier.new,
    );

class DeviceAuthNotifier extends Notifier<DeviceAuthState> {
  Timer? _pollTimer;
  DeviceAuthorization? _authorization;
  Duration _pollInterval = Duration.zero;
  int _session = 0;

  @override
  DeviceAuthState build() {
    ref.onDispose(_dispose);
    return const DeviceAuthState();
  }

  Future<void> start() async {
    if (state.isActive) return;
    if (ref.read(githubAuthConfigProvider).clientId.isEmpty) {
      state = const DeviceAuthState(
        phase: DeviceAuthPhase.failure,
        message: '缺少 GitHub Client ID，请使用构建参数配置后重试',
      );
      return;
    }

    final session = _beginSession();
    state = const DeviceAuthState(phase: DeviceAuthPhase.requestingCode);

    final result = await ref
        .read(githubAuthGatewayProvider)
        .requestDeviceCode();
    if (!_isCurrent(session)) return;

    switch (result) {
      case DeviceCodeSuccess(:final authorization):
        _authorization = authorization;
        _pollInterval = authorization.interval;
        final now = ref.read(currentTimeProvider)();
        state = DeviceAuthState(
          phase: DeviceAuthPhase.waitingAuthorization,
          userCode: authorization.userCode,
          verificationUri: authorization.verificationUri,
          expiresAt: now.add(authorization.expiresIn),
        );
        _schedulePoll(session);
      case DeviceCodeFailure(:final error):
        state = DeviceAuthState(
          phase: DeviceAuthPhase.failure,
          message: _errorMessage(error),
        );
    }
  }

  void cancel() {
    _beginSession();
    state = const DeviceAuthState();
  }

  int _beginSession() {
    _session++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _authorization = null;
    _pollInterval = Duration.zero;
    return _session;
  }

  void _schedulePoll(int session) {
    if (!_isCurrent(session)) return;
    final expiresAt = state.expiresAt;
    final now = ref.read(currentTimeProvider)();
    if (expiresAt == null || !now.isBefore(expiresAt)) {
      _finish(
        session,
        const DeviceAuthState(
          phase: DeviceAuthPhase.expired,
          message: '验证码已过期，请重新登录',
        ),
      );
      return;
    }

    final remaining = expiresAt.difference(now);
    final delay = remaining < _pollInterval ? remaining : _pollInterval;
    _pollTimer = ref.read(deviceAuthTimerFactoryProvider)(
      delay,
      () => unawaited(_poll(session)),
    );
  }

  Future<void> _poll(int session) async {
    if (!_isCurrent(session)) return;
    final authorization = _authorization;
    final expiresAt = state.expiresAt;
    final now = ref.read(currentTimeProvider)();
    if (authorization == null ||
        expiresAt == null ||
        !now.isBefore(expiresAt)) {
      _finish(
        session,
        const DeviceAuthState(
          phase: DeviceAuthPhase.expired,
          message: '验证码已过期，请重新登录',
        ),
      );
      return;
    }

    final result = await ref
        .read(githubAuthGatewayProvider)
        .pollToken(authorization.deviceCode);
    if (!_isCurrent(session)) return;

    switch (result) {
      case DeviceTokenAuthorizationPending():
        _schedulePoll(session);
      case DeviceTokenSlowDown():
        _pollInterval += const Duration(seconds: 5);
        _schedulePoll(session);
      case DeviceTokenSuccess(:final accessToken):
        state = const DeviceAuthState(phase: DeviceAuthPhase.loadingProfile);
        bool success;
        try {
          success = await ref.read(completeDeviceLoginProvider)(accessToken);
        } catch (_) {
          success = false;
        }
        if (!_isCurrent(session)) return;
        if (success) {
          _finish(session, const DeviceAuthState());
        } else {
          _finish(
            session,
            const DeviceAuthState(
              phase: DeviceAuthPhase.failure,
              message: 'GitHub 身份验证失败，请重新登录',
            ),
          );
        }
      case DeviceTokenExpired():
        _finish(
          session,
          const DeviceAuthState(
            phase: DeviceAuthPhase.expired,
            message: '验证码已过期，请重新登录',
          ),
        );
      case DeviceTokenAccessDenied():
        _finish(
          session,
          const DeviceAuthState(
            phase: DeviceAuthPhase.denied,
            message: 'GitHub 授权已取消',
          ),
        );
      case DeviceTokenFailure(:final error):
        if (error is DeviceAuthNetworkError) {
          state = DeviceAuthState(
            phase: DeviceAuthPhase.waitingAuthorization,
            userCode: state.userCode,
            verificationUri: state.verificationUri,
            expiresAt: state.expiresAt,
            message: '网络暂时不可用，正在继续等待授权',
          );
          _schedulePoll(session);
        } else {
          _finish(
            session,
            DeviceAuthState(
              phase: DeviceAuthPhase.failure,
              message: _errorMessage(error),
            ),
          );
        }
    }
  }

  void _finish(int session, DeviceAuthState nextState) {
    if (!_isCurrent(session)) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _authorization = null;
    state = nextState;
  }

  bool _isCurrent(int session) => ref.mounted && session == _session;

  String _errorMessage(DeviceAuthError error) {
    return switch (error) {
      DeviceAuthProtocolError(code: 'device_flow_disabled') =>
        '请先在 GitHub OAuth App 设置中启用 Device Flow',
      DeviceAuthProtocolError(:final description) => description,
      DeviceAuthNetworkError(:final description) => description,
    };
  }

  void _dispose() {
    _session++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _authorization = null;
  }
}
