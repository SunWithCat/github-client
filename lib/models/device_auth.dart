sealed class DeviceAuthError {
  const DeviceAuthError();
}

final class DeviceAuthProtocolError extends DeviceAuthError {
  const DeviceAuthProtocolError({
    required this.code,
    required this.description,
    this.documentationUri,
  });

  final String code;
  final String description;
  final Uri? documentationUri;
}

final class DeviceAuthNetworkError extends DeviceAuthError {
  const DeviceAuthNetworkError({required this.description, this.statusCode});

  final String description;
  final int? statusCode;
}

final class DeviceAuthorization {
  const DeviceAuthorization({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final Duration expiresIn;
  final Duration interval;
}

sealed class DeviceCodeResult {
  const DeviceCodeResult();
}

final class DeviceCodeSuccess extends DeviceCodeResult {
  const DeviceCodeSuccess(this.authorization);

  final DeviceAuthorization authorization;
}

final class DeviceCodeFailure extends DeviceCodeResult {
  const DeviceCodeFailure(this.error);

  final DeviceAuthError error;
}

sealed class DeviceTokenResult {
  const DeviceTokenResult();
}

final class DeviceTokenSuccess extends DeviceTokenResult {
  const DeviceTokenSuccess({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
  });

  final String accessToken;
  final String tokenType;
  final String scope;
}

final class DeviceTokenAuthorizationPending extends DeviceTokenResult {
  const DeviceTokenAuthorizationPending({this.description});

  final String? description;
}

final class DeviceTokenSlowDown extends DeviceTokenResult {
  const DeviceTokenSlowDown({this.description});

  final String? description;
}

final class DeviceTokenExpired extends DeviceTokenResult {
  const DeviceTokenExpired({this.description});

  final String? description;
}

final class DeviceTokenAccessDenied extends DeviceTokenResult {
  const DeviceTokenAccessDenied({this.description});

  final String? description;
}

final class DeviceTokenFailure extends DeviceTokenResult {
  const DeviceTokenFailure(this.error);

  final DeviceAuthError error;
}
