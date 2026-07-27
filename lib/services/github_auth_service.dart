import 'package:dio/dio.dart';
import 'package:ghclient/models/device_auth.dart';

abstract interface class GithubAuthGateway {
  Future<DeviceCodeResult> requestDeviceCode();

  Future<DeviceTokenResult> pollToken(String deviceCode);
}

final class GithubAuthService implements GithubAuthGateway {
  GithubAuthService({required String clientId, String scope = '', Dio? dio})
    : _clientId = _requireValue(clientId, 'clientId'),
      _scope = scope.trim(),
      _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://github.com'));

  final String _clientId;
  final String _scope;
  final Dio _dio;

  static const _headers = <String, String>{'Accept': 'application/json'};

  @override
  Future<DeviceCodeResult> requestDeviceCode() async {
    final data = <String, String>{'client_id': _clientId};
    if (_scope.isNotEmpty) data['scope'] = _scope;

    try {
      final response = await _dio.post<Object?>(
        '/login/device/code',
        data: data,
        options: _formOptions,
      );
      return _parseDeviceCode(response.data);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData != null) return _parseDeviceCode(responseData);
      return DeviceCodeFailure(_networkError(error));
    } catch (_) {
      return const DeviceCodeFailure(
        DeviceAuthNetworkError(description: '无法连接 GitHub'),
      );
    }
  }

  @override
  Future<DeviceTokenResult> pollToken(String deviceCode) async {
    final normalizedDeviceCode = deviceCode.trim();
    if (normalizedDeviceCode.isEmpty) {
      return const DeviceTokenFailure(
        DeviceAuthProtocolError(
          code: 'invalid_device_code',
          description: '设备代码不能为空',
        ),
      );
    }

    try {
      final response = await _dio.post<Object?>(
        '/login/oauth/access_token',
        data: <String, String>{
          'client_id': _clientId,
          'device_code': normalizedDeviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
        options: _formOptions,
      );
      return _parseToken(response.data);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData != null) return _parseToken(responseData);
      return DeviceTokenFailure(_networkError(error));
    } catch (_) {
      return const DeviceTokenFailure(
        DeviceAuthNetworkError(description: '无法连接 GitHub'),
      );
    }
  }

  Options get _formOptions => Options(
    contentType: Headers.formUrlEncodedContentType,
    headers: _headers,
  );

  DeviceCodeResult _parseDeviceCode(Object? data) {
    final json = _asJsonObject(data);
    if (json == null) return DeviceCodeFailure(_invalidResponse());

    final serverError = _protocolError(json);
    if (serverError != null) return DeviceCodeFailure(serverError);

    try {
      final expiresIn = _positiveInt(json, 'expires_in');
      final interval = _positiveInt(json, 'interval');
      final verificationUri = Uri.parse(
        _requiredString(json, 'verification_uri'),
      );
      if (!verificationUri.hasScheme || !verificationUri.hasAuthority) {
        throw const FormatException('verification_uri');
      }

      return DeviceCodeSuccess(
        DeviceAuthorization(
          deviceCode: _requiredString(json, 'device_code'),
          userCode: _requiredString(json, 'user_code'),
          verificationUri: verificationUri,
          expiresIn: Duration(seconds: expiresIn),
          interval: Duration(seconds: interval),
        ),
      );
    } on FormatException {
      return DeviceCodeFailure(_invalidResponse());
    }
  }

  DeviceTokenResult _parseToken(Object? data) {
    final json = _asJsonObject(data);
    if (json == null) return DeviceTokenFailure(_invalidResponse());

    final errorCode = json['error'];
    if (errorCode is String && errorCode.isNotEmpty) {
      final description = _optionalString(json, 'error_description');
      return switch (errorCode) {
        'authorization_pending' => DeviceTokenAuthorizationPending(
          description: description,
        ),
        'slow_down' => DeviceTokenSlowDown(description: description),
        'expired_token' ||
        'token_expired' => DeviceTokenExpired(description: description),
        'access_denied' => DeviceTokenAccessDenied(description: description),
        _ => DeviceTokenFailure(_protocolError(json)!),
      };
    }

    try {
      return DeviceTokenSuccess(
        accessToken: _requiredString(json, 'access_token'),
        tokenType: _requiredString(json, 'token_type'),
        scope: _string(json, 'scope'),
      );
    } on FormatException {
      return DeviceTokenFailure(_invalidResponse());
    }
  }

  static Map<String, Object?>? _asJsonObject(Object? data) {
    if (data is! Map) return null;
    final result = <String, Object?>{};
    for (final entry in data.entries) {
      if (entry.key is! String) return null;
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static DeviceAuthProtocolError? _protocolError(Map<String, Object?> json) {
    final code = json['error'];
    if (code is! String || code.isEmpty) return null;

    final uriValue = _optionalString(json, 'error_uri');
    return DeviceAuthProtocolError(
      code: code,
      description: _optionalString(json, 'error_description') ?? code,
      documentationUri: uriValue == null ? null : Uri.tryParse(uriValue),
    );
  }

  static DeviceAuthProtocolError _invalidResponse() =>
      const DeviceAuthProtocolError(
        code: 'invalid_response',
        description: 'GitHub 返回了无法识别的认证响应',
      );

  static DeviceAuthNetworkError _networkError(DioException error) =>
      DeviceAuthNetworkError(
        description: '无法连接 GitHub',
        statusCode: error.response?.statusCode,
      );

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = _string(json, key);
    if (value.isEmpty) throw FormatException(key);
    return value;
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) throw FormatException(key);
    return value;
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  static int _positiveInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int || value <= 0) throw FormatException(key);
    return value;
  }

  static String _requireValue(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, name, '不能为空');
    return normalized;
  }
}
