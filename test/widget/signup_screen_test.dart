import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:lugmatic_flutter/data/providers/auth_provider.dart';
import 'package:lugmatic_flutter/data/services/auth_service.dart';
import 'package:lugmatic_flutter/core/network/api_exception.dart';
import 'package:lugmatic_flutter/core/constants/app_strings.dart';
import 'package:lugmatic_flutter/features/auth/presentation/pages/signup_screen.dart';
import '../mocks/mocks.mocks.dart';

// Phone-sized viewport so the scrollable form is fully reachable without overflow
const _kPhoneSize = Size(800, 1200);

/// Scrolls until [finder] is visible then taps it.
Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

User _fakeUser({String firstName = 'Zara', String lastName = 'Fan'}) => User(
      id: 'usr_002',
      email: 'zara@lugmatic.com',
      firstName: firstName,
      lastName: lastName,
      role: 'user',
    );

Widget _buildSignUpScreen(AuthProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: const SignUpScreen(),
    ),
  );
}

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
    authProvider = AuthProvider(
      authService: mockAuthService,
      tokenStorage: mockTokenStorage,
      fcmService: mockFcmService,
    );
  });

  // ── Rendering ─────────────────────────────────────────────────────────────
  group('SignUpScreen renders correctly', () {
    testWidgets('shows Create Account title', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      expect(find.text(AppStrings.createAccount), findsOneWidget);
    });

    testWidgets('shows First Name and Last Name fields', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
    });

    testWidgets('shows Email Address field', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('shows Password and Confirm Password fields', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      expect(find.text(AppStrings.password), findsOneWidget);
      expect(find.text(AppStrings.confirmPassword), findsOneWidget);
    });

    testWidgets('shows Sign Up button', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      await tester.ensureVisible(find.text(AppStrings.signUp));
      expect(find.text(AppStrings.signUp), findsOneWidget);
    });

    testWidgets('shows sign in link', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      await tester.ensureVisible(find.text(' Sign in here'));
      expect(find.text(' Sign in here'), findsOneWidget);
    });
  });

  // ── Form Validation ───────────────────────────────────────────────────────
  group('SignUpScreen form validation', () {
    testWidgets('shows name required error on empty first name', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      await _scrollAndTap(tester, find.text(AppStrings.signUp));
      await tester.pump();

      expect(find.text(AppStrings.nameRequired), findsAtLeast(1));
    });

    testWidgets('shows email required error on empty email', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await _scrollAndTap(tester, find.text(AppStrings.signUp));
      await tester.pump();

      expect(find.text(AppStrings.emailRequired), findsOneWidget);
    });

    testWidgets('shows invalid email error on bad email format', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'notanemail');
      await _scrollAndTap(tester, find.text(AppStrings.signUp));
      await tester.pump();

      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
    });

    testWidgets('shows password too short error', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'zara@lugmatic.com');
      await tester.enterText(fields.at(3), 'short');
      await _scrollAndTap(tester, find.text(AppStrings.signUp).last);
      await tester.pump();

      expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
    });

    testWidgets('shows passwords do not match error', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildSignUpScreen(authProvider));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'zara@lugmatic.com');
      await tester.enterText(fields.at(3), 'Password1!');
      await tester.enterText(fields.at(4), 'DifferentPass');
      await _scrollAndTap(tester, find.text(AppStrings.signUp).last);
      await tester.pump();

      expect(find.text(AppStrings.passwordsDontMatch), findsOneWidget);
    });
  });

  // ── Auth Interactions ─────────────────────────────────────────────────────
  group('SignUpScreen auth interactions', () {
    testWidgets('calls AuthProvider.register with correct values on valid form',
        (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.register(
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser());

      await tester.pumpWidget(_buildSignUpScreen(authProvider));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'zara@lugmatic.com');
      await tester.enterText(fields.at(3), 'Secur3Pass!');
      await tester.enterText(fields.at(4), 'Secur3Pass!');

      await _scrollAndTap(tester, find.text(AppStrings.signUp).last);
      await tester.pumpAndSettle();

      verify(mockAuthService.register(
        firstName: 'Zara',
        lastName: 'Fan',
        email: 'zara@lugmatic.com',
        password: 'Secur3Pass!',
      )).called(1);
    });

    testWidgets('shows error SnackBar on registration failure', (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.register(
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        const ApiException(message: 'Email already in use', statusCode: 409),
      );

      await tester.pumpWidget(_buildSignUpScreen(authProvider));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'taken@lugmatic.com');
      await tester.enterText(fields.at(3), 'Secur3Pass!');
      await tester.enterText(fields.at(4), 'Secur3Pass!');

      await _scrollAndTap(tester, find.text(AppStrings.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('navigates to email verification screen on successful register',
        (tester) async {
      tester.view.physicalSize = _kPhoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(mockAuthService.register(
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _fakeUser());
      when(mockFcmService.registerToken()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSignUpScreen(authProvider));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Zara');
      await tester.enterText(fields.at(1), 'Fan');
      await tester.enterText(fields.at(2), 'zara@lugmatic.com');
      await tester.enterText(fields.at(3), 'Secur3Pass!');
      await tester.enterText(fields.at(4), 'Secur3Pass!');

      // Overflow suppression is already active via setUp.
      await _scrollAndTap(tester, find.text(AppStrings.signUp).last);
      // Pump through the page transition animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Create Account title should be gone — we've navigated away
      expect(find.text(AppStrings.createAccount), findsNothing);
    });
  });
}
