import 'app_config.dart';

class DevConfig implements AppConfig {
  const DevConfig();

  @override
  String get env => 'dev';

  @override
  bool get useFirebase => true;

  @override
  String get generationApiBaseUrl => 'https://api-dev.closetapp.com';

  @override
  FirebaseOptions get firebaseOptions => const FirebaseOptions(
        apiKey: 'REPLACE_WITH_DEV_API_KEY',
        appId: 'REPLACE_WITH_DEV_APP_ID',
        messagingSenderId: 'REPLACE_WITH_DEV_SENDER_ID',
        projectId: 'closet-app-dev',
        storageBucket: 'closet-app-dev.appspot.com',
      );
}
