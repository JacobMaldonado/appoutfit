import 'app_config.dart';

class DevConfig implements AppConfig {
  const DevConfig();

  @override
  String get env => 'dev';

  @override
  bool get useFirebase => true;

  @override
  String get generationApiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dev.closetapp.com',
  );
}
