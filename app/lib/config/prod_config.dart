import 'app_config.dart';

class ProdConfig implements AppConfig {
  const ProdConfig();

  @override
  String get env => 'prod';

  @override
  bool get useFirebase => true;

  @override
  String get generationApiBaseUrl => 'https://api.closetapp.com';

  @override
  FirebaseOptions get firebaseOptions => const FirebaseOptions(
        apiKey: 'REPLACE_WITH_PROD_API_KEY',
        appId: 'REPLACE_WITH_PROD_APP_ID',
        messagingSenderId: 'REPLACE_WITH_PROD_SENDER_ID',
        projectId: 'closet-app-prod',
        storageBucket: 'closet-app-prod.appspot.com',
      );
}
