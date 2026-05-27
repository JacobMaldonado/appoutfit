/// Represents the currently authenticated user.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}

abstract class AuthService {
  /// Emits the current user or null when signed out.
  Stream<AppUser?> get userStream;

  /// Returns the current user synchronously (null if signed out).
  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AppUser> createAccountWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
}
