import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/services/auth/mock_auth_service.dart';

void main() {
  late MockAuthService authService;

  setUp(() => authService = MockAuthService());
  tearDown(() => authService.dispose());

  test('currentUser is null before any sign-in', () {
    expect(authService.currentUser, isNull);
  });

  test('signInWithEmail sets currentUser', () async {
    await authService.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );
    expect(authService.currentUser, isNotNull);
    expect(authService.currentUser!.id, isNotEmpty);
  });

  test('userStream emits a user after sign-in', () async {
    final future = authService.userStream.first;
    await authService.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );
    final user = await future;
    expect(user, isNotNull);
  });

  test('signOut clears currentUser', () async {
    await authService.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );
    await authService.signOut();
    expect(authService.currentUser, isNull);
  });

  test('createAccountWithEmail signs user in', () async {
    await authService.createAccountWithEmail(
      email: 'new@example.com',
      password: 'password123',
    );
    expect(authService.currentUser, isNotNull);
  });

  test('signInWithGoogle signs user in', () async {
    await authService.signInWithGoogle();
    expect(authService.currentUser, isNotNull);
  });
}

