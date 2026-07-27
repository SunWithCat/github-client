class AppConfig {
  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
  );
  static const String githubOAuthScopes = String.fromEnvironment(
    'GITHUB_OAUTH_SCOPES',
  );

  static bool get isGithubAuthConfigured => githubClientId.isNotEmpty;
}
