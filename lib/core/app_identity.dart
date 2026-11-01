/// 应用仓库与作者身份常量
class AppIdentity {
  AppIdentity._();

  static const String repoOwner = 'SunWithCat';
  static const String repoName = 'github-client';
  static const String developerUrl = 'https://github.com/$repoOwner';
  static const String repoUrl = 'https://github.com/$repoOwner/$repoName';
  static const String releasesUrl = '$repoUrl/releases';
}
