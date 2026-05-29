import 'dart:async';
import 'auth_service.dart';

/// Mock auth service for the local environment. Immediately returns a hardcoded user.
class MockAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  static const _mockUser = AppUser(
    id: 'mock-user-001',
    email: 'demo@closetapp.com',
    displayName: 'Demo User',
  );

  @override
  Stream<AppUser?> get userStream => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  @override
  Future<AppUser> signInWithGoogle() => _signIn();

  @override
  Future<AppUser> signInWithApple() => _signIn();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _signIn();

  @override
  Future<AppUser> createAccountWithEmail({
    required String email,
    required String password,
  }) =>
      _signIn();

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String?> getIdToken() async => 'mock-firebase-id-token';

  Future<AppUser> _signIn() async {
    _current = _mockUser;
    _controller.add(_mockUser);
    return _mockUser;
  }

  void dispose() => _controller.close();
}
