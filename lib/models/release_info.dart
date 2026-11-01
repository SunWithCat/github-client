import 'package:ghclient/core/app_identity.dart';

/// 归一化版本号：去除首尾空白、前导 v/V 以及 +build 构建后缀
String normalizeVersion(String rawVersion) {
  var cleaned = rawVersion.trim();
  if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
    cleaned = cleaned.substring(1).trim();
  }
  final plusIndex = cleaned.indexOf('+');
  if (plusIndex != -1) {
    cleaned = cleaned.substring(0, plusIndex).trim();
  }
  return cleaned;
}

/// GitHub Release 信息模型
class ReleaseInfo {
  static const String defaultReleasesUrl = AppIdentity.releasesUrl;

  final String tagName;
  final String version;
  final String htmlUrl;
  final String? body;
  final String? name;

  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.htmlUrl,
    this.body,
    this.name,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final rawTag = (json['tag_name'] as String? ?? '').trim();
    final rawUrl = (json['html_url'] as String? ?? '').trim();
    final rawBody = (json['body'] as String?)?.trim();
    final rawName = (json['name'] as String?)?.trim();

    return ReleaseInfo(
      tagName: rawTag,
      version: normalizeVersion(rawTag),
      htmlUrl: rawUrl.isNotEmpty ? rawUrl : defaultReleasesUrl,
      body: (rawBody != null && rawBody.isNotEmpty) ? rawBody : null,
      name: (rawName != null && rawName.isNotEmpty) ? rawName : null,
    );
  }
}
