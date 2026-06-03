import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../data/repositories/impl/local_wardrobe_repository.dart';
import '../../data/repositories/impl/local_outfit_repository.dart';
import '../../data/repositories/impl/firestore_wardrobe_repository.dart';
import '../../data/repositories/impl/firestore_outfit_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../../data/services/auth/mock_auth_service.dart';
import '../../data/services/auth/firebase_auth_service.dart';
import '../../data/services/generation/generation_service.dart';
import '../../data/services/generation/mock_generation_service.dart';
import '../../data/services/generation/remote_generation_service.dart';
import '../../data/services/storage/storage_service.dart';
import '../../data/services/storage/mock_storage_service.dart';
import '../../data/services/storage/firebase_storage_service.dart';
import '../notifiers/user_profile_notifier.dart';
import '../notifiers/mass_capture_notifier.dart';
import '../services/background_removal_service.dart';
import '../../data/services/classification/clothing_classification_service.dart';

final sl = GetIt.instance;

/// Call this once from each main_*.dart entry point.
///
/// For dev/prod, pass the Firebase instances after Firebase.initializeApp().
/// For local, omit them — mocks will be used instead.
Future<void> setupServiceLocator(
  AppConfig config, {
  FirebaseInstances? firebase,
}) async {
  sl.registerSingleton<AppConfig>(config);
  sl.registerSingleton<http.Client>(http.Client());
  sl.registerSingleton<BackgroundRemovalService>(BackgroundRemovalService());
  sl.registerSingleton<UserProfileNotifier>(
    UserProfileNotifier(useFirebase: config.useFirebase),
  );

  if (config.useFirebase && firebase != null) {
    _registerFirebaseServices(firebase, config);
  } else {
    _registerLocalServices();
  }

  // Initialize profile notifier after auth is registered
  sl<UserProfileNotifier>().initialize(sl<AuthService>());
}

void _registerLocalServices() {
  final wardrobeRepo = LocalWardrobeRepository();
  final outfitRepo = LocalOutfitRepository();

  sl.registerSingleton<WardrobeRepository>(wardrobeRepo);
  sl.registerSingleton<OutfitRepository>(outfitRepo);
  sl.registerSingleton<AuthService>(MockAuthService());
  sl.registerSingleton<StorageService>(MockStorageService());
  sl.registerFactory<GenerationService>(
    () => MockGenerationService(
      outfitRepository: sl<OutfitRepository>(),
      wardrobeRepository: sl<WardrobeRepository>(),
    ),
  );
  _registerCaptureServices();
}

void _registerFirebaseServices(
  FirebaseInstances firebase,
  AppConfig config,
) {
  sl.registerSingleton<WardrobeRepository>(
    FirestoreWardrobeRepository(firebase.firestore),
  );
  sl.registerSingleton<OutfitRepository>(
    FirestoreOutfitRepository(firebase.firestore),
  );
  sl.registerSingleton<AuthService>(FirebaseAuthService(firebase.auth));
  sl.registerSingleton<StorageService>(
    FirebaseStorageService(firebase.storage),
  );
  sl.registerFactory<GenerationService>(
    () => RemoteGenerationService(
      config: sl<AppConfig>(),
      httpClient: sl<http.Client>(),
      authService: sl<AuthService>(),
    ),
  );
  _registerCaptureServices();
}

void _registerCaptureServices() {
  sl.registerSingleton<ClothingClassificationService>(
    ClothingClassificationService(
      config: sl<AppConfig>(),
      httpClient: sl<http.Client>(),
      authService: sl<AuthService>(),
    ),
  );
  sl.registerSingleton<MassCaptureNotifier>(
    MassCaptureNotifier(
      wardrobeRepo: sl<WardrobeRepository>(),
      storageService: sl<StorageService>(),
      classificationService: sl<ClothingClassificationService>(),
    ),
  );
}

/// Container for Firebase singletons passed from the entry points.
/// Using a plain class avoids coupling the service locator to firebase imports.
class FirebaseInstances {
  const FirebaseInstances({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  /// FirebaseFirestore instance
  final dynamic firestore;

  /// FirebaseAuth instance
  final dynamic auth;

  /// FirebaseStorage instance
  final dynamic storage;
}

