import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghclient/common/utils/toast_utils.dart';
import 'package:ghclient/core/device_auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);
typedef ClipboardWriter = Future<void> Function(String text);

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

final clipboardWriterProvider = Provider<ClipboardWriter>((ref) {
  return (text) => Clipboard.setData(ClipboardData(text: text));
});

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(deviceAuthProvider);
    ref.listen(deviceAuthProvider, (previous, next) {
      if (next.phase == DeviceAuthPhase.waitingAuthorization &&
          previous?.phase != DeviceAuthPhase.waitingAuthorization) {
        _startCountdown();
      } else if (next.phase != DeviceAuthPhase.waitingAuthorization) {
        _countdownTimer?.cancel();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildContent(authState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DeviceAuthState authState) {
    return switch (authState.phase) {
      DeviceAuthPhase.idle => _buildIdle(),
      DeviceAuthPhase.requestingCode => _buildLoading('正在连接 GitHub...'),
      DeviceAuthPhase.waitingAuthorization => _buildWaiting(authState),
      DeviceAuthPhase.loadingProfile => _buildLoading('正在验证 GitHub 帐号...'),
      DeviceAuthPhase.denied ||
      DeviceAuthPhase.expired ||
      DeviceAuthPhase.failure => _buildFailure(authState),
    };
  }

  Widget _buildIdle() {
    return Column(
      key: const ValueKey('device_auth_idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(OctIcons.mark_github_16, size: 48),
        const SizedBox(height: 18),
        Text(
          '登录到 GitHub',
          style: GoogleFonts.notoSansSc(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('device_auth_start'),
          onPressed: () => ref.read(deviceAuthProvider.notifier).start(),
          icon: const Icon(OctIcons.sign_in_16),
          label: const Text('使用 GitHub 登录'),
        ),
      ],
    );
  }

  Widget _buildLoading(String message) {
    return Column(
      key: ValueKey(message),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 18),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildWaiting(DeviceAuthState authState) {
    final userCode = authState.userCode!;
    final verificationUri = authState.verificationUri!;
    return Column(
      key: const ValueKey('device_auth_waiting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(OctIcons.device_mobile_16, size: 40),
        const SizedBox(height: 16),
        Text(
          '在 GitHub 完成授权',
          style: GoogleFonts.notoSansSc(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '使用下面的验证码继续登录',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            userCode,
            key: const ValueKey('device_auth_user_code'),
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _remainingText(authState.expiresAt),
          key: const ValueKey('device_auth_countdown'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (authState.message != null) ...[
          const SizedBox(height: 8),
          Text(
            authState.message!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('device_auth_open_github'),
          onPressed: () => _copyAndOpen(userCode, verificationUri),
          icon: const Icon(Icons.open_in_new),
          label: const Text('复制并打开 GitHub'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('device_auth_cancel'),
          onPressed: () => ref.read(deviceAuthProvider.notifier).cancel(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildFailure(DeviceAuthState authState) {
    return Column(
      key: const ValueKey('device_auth_failure'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 40,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(authState.message ?? '登录失败，请重试', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('device_auth_retry'),
          onPressed: () => ref.read(deviceAuthProvider.notifier).start(),
          icon: const Icon(Icons.refresh),
          label: const Text('重新登录'),
        ),
      ],
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _remainingText(DateTime? expiresAt) {
    if (expiresAt == null) return '';
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return '验证码即将过期';
    final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (seconds % 60).toString().padLeft(2, '0');
    return '验证码有效期 $minutesPart:$secondsPart';
  }

  Future<void> _copyAndOpen(String userCode, Uri verificationUri) async {
    await ref.read(clipboardWriterProvider)(userCode);
    final opened = await ref.read(externalUrlLauncherProvider)(verificationUri);
    if (!mounted || opened) return;
    ToastUtils.show(context, message: '无法打开浏览器，请稍后重试', type: ToastType.error);
  }
}
