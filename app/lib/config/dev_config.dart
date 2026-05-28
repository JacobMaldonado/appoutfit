import 'app_config.dart';

class DevConfig implements AppConfig {
  const DevConfig();

  @override
  String get env => 'dev';

  @override
  bool get useFirebase => true;

  @override
  String get generationApiBaseUrl => 'https://api-dev.closetapp.com';
}
