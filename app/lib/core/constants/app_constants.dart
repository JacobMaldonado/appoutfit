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

  // Generation API endpoints
  static const String generateEndpoint = '/generate';

  // Supported mood values (kept in sync with Mood enum)
  static const List<String> moods = [
    'casual',
    'work',
    'brunch',
    'night',
    'active',
  ];
}
