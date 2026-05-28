import 'app_config.dart';

class ProdConfig implements AppConfig {
  const ProdConfig();

  @override
  String get env => 'prod';

  @override
  bool get useFirebase => true;

  @override
  String get generationApiBaseUrl => 'https://api.closetapp.com';
}
