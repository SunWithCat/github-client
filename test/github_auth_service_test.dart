import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/models/device_auth.dart';
import 'package:ghclient/services/github_auth_service.dart';

void main() {
  group('GithubAuthService', () {
    test('申请设备码使用表单编码且不发送客户端密钥', () async {
      RequestOptions? capturedRequest;
      final service = GithubAuthService(
        clientId: 'public-client-id',
        scope: 'read:user repo',
        dio: _dioReturning(<String, Object?>{
          'device_code': 'device-code',
          'user_code': 'ABCD-1234',
          'verification_uri': 'https://github.com/login/device',
          'expires_in': 900,
          'interval': 5,
        }, onRequest: (request) => capturedRequest = request),
      );

      final result = await service.requestDeviceCode();

      expect(result, isA<DeviceCodeSuccess>());
      final authorization = (result as DeviceCodeSuccess).authorization;
      expect(authorization.userCode, 'ABCD-1234');
      expect(authorization.expiresIn, const Duration(minutes: 15));
      expect(authorization.interval, const Duration(seconds: 5));
      expect(capturedRequest?.path, '/login/device/code');
      expect(capturedRequest?.contentType, Headers.formUrlEncodedContentType);
      expect(capturedRequest?.headers['Accept'], 'application/json');
      expect(capturedRequest?.data, <String, String>{
        'client_id': 'public-client-id',
        'scope': 'read:user repo',
      });
      expect(
        (capturedRequest?.data as Map).containsKey('client_secret'),
        isFalse,
      );
    });

    test('授权成功返回访问令牌', () async {
      final service = GithubAuthService(
        clientId: 'client-id',
        dio: _dioReturning(<String, Object?>{
          'access_token': 'token',
          'token_type': 'bearer',
          'scope': 'repo,read:user',
        }),
      );

      final result = await service.pollToken('device-code');

      expect(result, isA<DeviceTokenSuccess>());
      final success = result as DeviceTokenSuccess;
      expect(success.accessToken, 'token');
      expect(success.tokenType, 'bearer');
      expect(success.scope, 'repo,read:user');
    });

    test('轮询请求包含 Device Flow 标准参数', () async {
      RequestOptions? capturedRequest;
      final service = GithubAuthService(
        clientId: 'client-id',
        dio: _dioReturning(<String, Object?>{
          'error': 'authorization_pending',
        }, onRequest: (request) => capturedRequest = request),
      );

      await service.pollToken(' device-code ');

      expect(capturedRequest?.data, <String, String>{
        'client_id': 'client-id',
        'device_code': 'device-code',
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      });
      expect(
        (capturedRequest?.data as Map).containsKey('client_secret'),
        isFalse,
      );
    });

    test('将等待、降速、过期和拒绝映射为独立结果', () async {
      final cases = <String, Type>{
        'authorization_pending': DeviceTokenAuthorizationPending,
        'slow_down': DeviceTokenSlowDown,
        'expired_token': DeviceTokenExpired,
        'token_expired': DeviceTokenExpired,
        'access_denied': DeviceTokenAccessDenied,
      };

      for (final entry in cases.entries) {
        final service = GithubAuthService(
          clientId: 'client-id',
          dio: _dioReturning(<String, Object?>{
            'error': entry.key,
            'error_description': 'description',
          }),
        );

        final result = await service.pollToken('device-code');

        expect(result.runtimeType, entry.value, reason: entry.key);
      }
    });

    test('未知 OAuth 错误返回结构化协议错误', () async {
      final service = GithubAuthService(
        clientId: 'client-id',
        dio: _dioReturning(<String, Object?>{
          'error': 'incorrect_device_code',
          'error_description': 'The device code is invalid.',
          'error_uri': 'https://docs.github.com/',
        }),
      );

      final result = await service.pollToken('device-code');

      expect(result, isA<DeviceTokenFailure>());
      final error = (result as DeviceTokenFailure).error;
      expect(error, isA<DeviceAuthProtocolError>());
      final protocolError = error as DeviceAuthProtocolError;
      expect(protocolError.code, 'incorrect_device_code');
      expect(protocolError.description, 'The device code is invalid.');
      expect(
        protocolError.documentationUri,
        Uri.parse('https://docs.github.com/'),
      );
    });

    test('畸形成功响应返回协议错误而不是抛出异常', () async {
      final service = GithubAuthService(
        clientId: 'client-id',
        dio: _dioReturning(<String, Object?>{'access_token': 'token'}),
      );

      final result = await service.pollToken('device-code');

      final error = (result as DeviceTokenFailure).error;
      expect(error, isA<DeviceAuthProtocolError>());
      expect((error as DeviceAuthProtocolError).code, 'invalid_response');
    });
  });
}

Dio _dioReturning(
  Object? data, {
  void Function(RequestOptions request)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://github.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        onRequest?.call(request);
        handler.resolve(Response<Object?>(requestOptions: request, data: data));
      },
    ),
  );
  return dio;
}
