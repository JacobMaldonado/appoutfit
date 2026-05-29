import 'app_config.dart';

class LocalConfig implements AppConfig {
  const LocalConfig();

  @override
  String get env => 'local';

  @override
  bool get useFirebase => false;

  @override
  String get generationApiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
