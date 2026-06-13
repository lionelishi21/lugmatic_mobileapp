import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:lugmatic_flutter/data/providers/auth_provider.dart';
import 'package:lugmatic_flutter/data/services/auth_service.dart';
import 'package:lugmatic_flutter/core/network/api_exception.dart';
import 'package:lugmatic_flutter/features/auth/presentation/pages/login_screen.dart';
import '../mocks/mocks.mocks.dart';

// Phone-sized viewport so the scrollable form is fully reachable without overflow
const _kPhoneSize = Size(800, 1200);

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

User _fakeUser() => const User(
      id: 'usr_001',
      email: 'fan@lugmatic.com',
      firstName: 'Leon',
      lastName: 'Beats',
      role: 'user',
    );

/// Wraps [LoginScreen] in the minimal scaffold needed for widget tests.
Widget _buildLoginScreen(AuthProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: const LoginScreen(),
    ),
  );
}

/// Scrolls until the widget matching [finder] is visible, then taps it.
Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

AuthProvider _makeProvider({
  required MockAuthService authService,
  required MockTokenStorage tokenStorage,
  MockFcmService? fcmService,
}) =>
    AuthProvider(
      authService: authService,
      tokenStorage: tokenStorage,
      fcmService: fcmService,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockAuthService mockAuthService;
  late MockTokenStorage mockTokenStorage;
  late MockFcmService mockFcmService;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    mockTokenStorage = MockTokenStorage();
    mockFcmService = MockFcmService();
    authProvider = _makeProvider(
      authService: mockAuthService,
      tokenStorage: mockTokenStorage,
      fcmService: mockFcmService,
    );
  });

  // Sets phone-sized viewport for every test in this file
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ── Rendering ─────────────────────────────────────────────────────────────
  group('LoginScreen renders correctly', () {
    testWidgets('shows Welcome Back title', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows email and password text fields', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('shows Log In button', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.ensureVisible(find.text('Log In'));
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('shows Forgot Password link', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('shows Sign up for free link', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.ensureVisible(find.text(' Sign up for free'));
      expect(find.text(' Sign up for free'), findsOneWidget);
    });
  });

  // ── Form Validation ───────────────────────────────────────────────────────
  group('LoginScreen form validation', () {
    testWidgets('shows email required error on empty submit', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows email invalid error on bad format', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password required error when password is empty',
        (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows password too short error', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });

  // ── Auth Interactions ─────────────────────────────────────────────────────
  group('LoginScreen auth interactions', () {
    testWidgets('calls AuthProvider.login with correct credentials',
        (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser());

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'fan@lugmatic.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Secur3Pass!');
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pumpAndSettle();

      verify(mockAuthService.login(
        email: 'fan@lugmatic.com',
        password: 'Secur3Pass!',
      )).called(1);
    });

    testWidgets('shows error SnackBar on login failure', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        const ApiException(message: 'Invalid credentials', statusCode: 401),
      );

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'fan@lugmatic.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await _scrollAndTap(tester, find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('navigates away from LoginScreen on successful login',
        (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser());
      when(mockFcmService.registerToken()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildLoginScreen(authProvider));
      await tester.enterText(find.byType(TextFormField).first, 'fan@lugmatic.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Secur3Pass!');
      await _scrollAndTap(tester, find.text('Log In'));
      
      // Pump through the transition animation manually.
      // We don't use pumpAndSettle here because the destination route (HomePage)
      // requires providers (e.g. ApiClient) that aren't mocked in this isolated
      // test environment, which would cause a ProviderNotFoundException.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // LoginScreen should no longer show its title
      expect(find.text('Welcome Back'), findsNothing);
    });
  });

  // ── Password Toggle ───────────────────────────────────────────────────────
  group('LoginScreen password toggle', () {
    testWidgets('password field is obscured by default', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('tapping eye icon toggles password visibility', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildLoginScreen(authProvider));

      // Scroll to ensure suffix icon is visible, then tap
      await tester.ensureVisible(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isFalse);
    });
  });
}
