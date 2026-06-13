import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lugmatic_flutter/data/providers/auth_provider.dart';
import 'package:lugmatic_flutter/data/services/auth_service.dart';
import 'package:lugmatic_flutter/core/network/api_exception.dart';
import '../mocks/mocks.mocks.dart';

// Convenience factory — builds a typical user from the Lugmatic backend
User _fakeUser({
  String id = 'usr_test_001',
  String email = 'fan@lugmatic.com',
  String firstName = 'Leon',
  String lastName = 'Beats',
  String role = 'user',
}) =>
    User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
    );

void main() {
  late MockAuthService mockAuthService;
  late MockTokenStorage mockTokenStorage;
  late MockFcmService mockFcmService;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    mockTokenStorage = MockTokenStorage();
    mockFcmService = MockFcmService();

    authProvider = AuthProvider(
      authService: mockAuthService,
      tokenStorage: mockTokenStorage,
      fcmService: mockFcmService,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider initial state', () {
    test('starts with AuthStatus.initial', () {
      expect(authProvider.status, AuthStatus.initial);
    });

    test('user is null at start', () {
      expect(authProvider.user, isNull);
    });

    test('isAuthenticated is false at start', () {
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('isLoading is false at start', () {
      expect(authProvider.isLoading, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider.login()', () {
    test('transitions to authenticated and returns true on success', () async {
      final user = _fakeUser();
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => user);

      final result = await authProvider.login(
        email: 'fan@lugmatic.com',
        password: 'Secur3Pass!',
      );

      expect(result, isTrue);
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.user, equals(user));
      expect(authProvider.errorMessage, isNull);
    });

    test('sets loading state during login', () async {
      final user = _fakeUser();
      // Delay the mock so we can observe intermediate state
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return user;
      });

      bool wasLoading = false;
      authProvider.addListener(() {
        if (authProvider.isLoading) wasLoading = true;
      });

      await authProvider.login(email: 'fan@lugmatic.com', password: 'pass');
      expect(wasLoading, isTrue);
    });

    test('transitions to error and returns false on ApiException', () async {
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        const ApiException(message: 'Invalid credentials', statusCode: 401),
      );

      final result = await authProvider.login(
        email: 'fan@lugmatic.com',
        password: 'wrongpassword',
      );

      expect(result, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, 'Invalid credentials');
      expect(authProvider.user, isNull);
    });

    test('transitions to error on unexpected exception', () async {
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('network failed'));

      final result = await authProvider.login(
        email: 'fan@lugmatic.com',
        password: 'pass',
      );

      expect(result, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, 'An unexpected error occurred');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider.register()', () {
    test('returns true and sets authenticated on success', () async {
      final user = _fakeUser(firstName: 'Zara', lastName: 'Fan');
      when(mockAuthService.register(
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => user);

      final result = await authProvider.register(
        firstName: 'Zara',
        lastName: 'Fan',
        email: 'zara@lugmatic.com',
        password: 'MyP@ssword1',
      );

      expect(result, isTrue);
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.user?.firstName, 'Zara');
    });

    test('returns false and sets error message on ApiException', () async {
      when(mockAuthService.register(
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        const ApiException(message: 'Email already in use', statusCode: 409),
      );

      final result = await authProvider.register(
        firstName: 'Zara',
        lastName: 'Fan',
        email: 'taken@lugmatic.com',
        password: 'MyP@ssword1',
      );

      expect(result, isFalse);
      expect(authProvider.errorMessage, 'Email already in use');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider.logout()', () {
    test('clears user and sets unauthenticated', () async {
      // Seed authenticated state first
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser());
      await authProvider.login(email: 'fan@lugmatic.com', password: 'pass');
      expect(authProvider.isAuthenticated, isTrue);

      when(mockAuthService.logout()).thenAnswer((_) async {});
      when(mockTokenStorage.clearTokens()).thenAnswer((_) async {});

      await authProvider.logout();

      expect(authProvider.user, isNull);
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.errorMessage, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider.checkAuthStatus()', () {
    test('sets authenticated when valid tokens and user returned', () async {
      when(mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
      when(mockAuthService.getCurrentUser())
          .thenAnswer((_) async => _fakeUser());

      await authProvider.checkAuthStatus();

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.user, isNotNull);
    });

    test('sets unauthenticated when no tokens stored', () async {
      when(mockTokenStorage.hasTokens()).thenAnswer((_) async => false);

      await authProvider.checkAuthStatus();

      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.user, isNull);
    });

    test('clears tokens and sets unauthenticated when token is stale', () async {
      when(mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);
      when(mockTokenStorage.clearTokens()).thenAnswer((_) async {});

      await authProvider.checkAuthStatus();

      expect(authProvider.status, AuthStatus.unauthenticated);
      verify(mockTokenStorage.clearTokens()).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider.clearError()', () {
    test('clears errorMessage', () async {
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(const ApiException(message: 'Bad creds', statusCode: 401));

      await authProvider.login(email: 'x@x.com', password: 'wrong');
      expect(authProvider.errorMessage, isNotNull);

      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthProvider role helpers', () {
    test('hasArtistRole is false for default user role', () async {
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser(role: 'user'));

      await authProvider.login(email: 'fan@lugmatic.com', password: 'pass');
      expect(authProvider.hasArtistRole, isFalse);
    });

    test('hasArtistRole is true for user with artist role', () async {
      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer(
        (_) async => User(
          id: '1',
          email: 'artist@lugmatic.com',
          firstName: 'DJ',
          lastName: 'Lug',
          role: 'artist',
        ),
      );

      await authProvider.login(email: 'artist@lugmatic.com', password: 'pass');
      expect(authProvider.hasArtistRole, isTrue);
    });
  });
}
