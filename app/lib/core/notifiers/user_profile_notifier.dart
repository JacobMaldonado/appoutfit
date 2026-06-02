import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../data/services/auth/auth_service.dart';

/// Caches the current user's profile (onboarding status, body type, profile
/// photo URL) and notifies the GoRouter when it changes so that redirect logic
/// can re-evaluate.
class UserProfileNotifier extends ChangeNotifier {
  UserProfileNotifier({bool useFirebase = false}) : _useFirebase = useFirebase;

  final bool _useFirebase;

  StreamSubscription<AppUser?>? _authSub;

  bool? _onboardingComplete;
  String? _bodyType;
  String? _profilePhotoUrl;

  bool? get onboardingComplete => _onboardingComplete;
  String? get bodyType => _bodyType;
  String? get profilePhotoUrl => _profilePhotoUrl;

  /// Subscribe to the auth stream so profile loads/clears automatically.
  void initialize(AuthService authService) {
    if (!_useFirebase) {
      _onboardingComplete = true;
      notifyListeners();
      return;
    }

    _authSub?.cancel();
    _authSub = authService.userStream.listen((user) {
      if (user == null) {
        _clear();
      } else {
        loadForUser(user.id);
      }
    });

    final current = authService.currentUser;
    if (current != null) {
      loadForUser(current.id);
    }
  }

  Future<void> loadForUser(String userId) async {
    if (!_useFirebase) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      final data = doc.data();
      _onboardingComplete = data?['onboardingComplete'] as bool? ?? false;
      _bodyType = data?['bodyType'] as String?;
      _profilePhotoUrl = data?['profilePhotoUrl'] as String?;
    } catch (e) {
      debugPrint('[UserProfileNotifier] loadForUser error: $e');
      _onboardingComplete = true; // Don't block on error
    }
    notifyListeners();
  }

  /// Mark onboarding as complete, optionally saving a body type or photo URL.
  Future<void> completeOnboarding(
    String userId, {
    String? bodyType,
    String? profilePhotoUrl,
  }) async {
    _onboardingComplete = true;
    if (bodyType != null) _bodyType = bodyType;
    if (profilePhotoUrl != null) _profilePhotoUrl = profilePhotoUrl;
    notifyListeners();

    if (!_useFirebase) return;
    try {
      final update = <String, dynamic>{'onboardingComplete': true};
      if (bodyType != null) update['bodyType'] = bodyType;
      if (profilePhotoUrl != null) update['profilePhotoUrl'] = profilePhotoUrl;
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(update, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserProfileNotifier] completeOnboarding error: $e');
    }
  }

  /// Update profile photo URL for an already-onboarded user (from Account screen).
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    _profilePhotoUrl = photoUrl;
    notifyListeners();

    if (!_useFirebase) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({'profilePhotoUrl': photoUrl}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserProfileNotifier] updateProfilePhoto error: $e');
    }
  }

  /// Update body type for an already-onboarded user (from Account screen).
  Future<void> updateBodyType(String userId, String bodyType) async {
    _bodyType = bodyType;
    notifyListeners();

    if (!_useFirebase) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({'bodyType': bodyType}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[UserProfileNotifier] updateBodyType error: $e');
    }
  }

  void _clear() {
    _onboardingComplete = null;
    _bodyType = null;
    _profilePhotoUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
