abstract class AppConstants {
  // Firestore collection paths
  static const String usersCollection = 'users';
  static const String wardrobeCollection = 'wardrobe';
  static const String outfitsCollection = 'outfits';
  static const String historyCollection = 'history';

  // Route names
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeWardrobe = '/wardrobe';
  static const String routeAddItem = '/wardrobe/add';
  static const String routeSuggest = '/suggest';
  static const String routeSaved = '/saved';
  static const String routeHistory = '/history';

  static const String routeItemDetail = '/wardrobe/item-detail';
  static const String routeOutfitDetail = '/outfit-detail';
  static const String routeAccount = '/account';
  static const String routeOnboarding = '/onboarding';
  static const String generateEndpoint = '/v1/suggestions';

  // Supported mood values (kept in sync with Mood enum)
  static const List<String> moods = [
    'casual',
    'work',
    'brunch',
    'night',
    'active',
  ];
}
