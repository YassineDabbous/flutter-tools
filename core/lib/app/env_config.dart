enum AppEnvironment { dev, staging, prod }

/// Configuration class supporting multiple environments.
class EnvConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final String apiKey;

  const EnvConfig({
    required this.environment,
    required this.baseUrl,
    required this.apiKey,
  });

  static EnvConfig dev({required String baseUrl, String apiKey = ''}) =>
      EnvConfig(
        environment: AppEnvironment.dev,
        baseUrl: baseUrl,
        apiKey: apiKey,
      );

  static EnvConfig prod({required String baseUrl, String apiKey = ''}) =>
      EnvConfig(
        environment: AppEnvironment.prod,
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
}
