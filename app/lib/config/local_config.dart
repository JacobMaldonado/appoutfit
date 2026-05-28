import 'app_config.dart';

class LocalConfig implements AppConfig {
  const LocalConfig();

  @override
  String get env => 'local';

  @override
  bool get useFirebase => false;

  @override
  String get generationApiBaseUrl => 'http://localhost:8080';
}
