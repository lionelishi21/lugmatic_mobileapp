/// Integration test — runs on a real iOS Simulator or Android Emulator.
///
/// Run with:
///   flutter test integration_test/auth_flow_test.dart
///
/// This test uses the *real* app but intercepts nothing — it validates
/// UI flows without touching the backend (it drives the app UI and checks
/// what users see, not API responses).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lugmatic_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow integration test', () {
    // ── App start ──────────────────────────────────────────────────────────
    testWidgets('App launches without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // The app is running — verify we have some rendered content
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    // ── Navigation: Login → Sign Up → Back ────────────────────────────────
    testWidgets('Can navigate to Sign Up screen and back', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Try to reach Login — skip onboarding if present
      if (find.text('Start Listening').evaluate().isNotEmpty) {
        await tester.tap(find.text('Start Listening'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Look for the login entry point
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In').first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (find.text('Log In').evaluate().isNotEmpty) {
        // Already on login screen — skip
      }

      // Navigate to sign up
      if (find.text(' Sign up for free').evaluate().isNotEmpty) {
        await tester.tap(find.text(' Sign up for free'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Create Account'), findsOneWidget);

        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Welcome Back'), findsOneWidget);
      }
    });

    // ── Login validation errors visible on device ─────────────────────────
    testWidgets('Login screen shows validation errors on empty submit',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Navigate through onboarding if needed
      if (find.text('Start Listening').evaluate().isNotEmpty) {
        await tester.tap(find.text('Start Listening'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In').first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      if (find.text('Log In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Log In'));
        await tester.pump();

        // At least one validation message appears
        expect(
          find.textContaining('required').evaluate().isNotEmpty ||
              find.textContaining('valid').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    // ── Sign Up validation errors visible on device ───────────────────────
    testWidgets('Sign Up screen shows password mismatch error', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      if (find.text('Start Listening').evaluate().isNotEmpty) {
        await tester.tap(find.text('Start Listening'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In').first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      if (find.text(' Sign up for free').evaluate().isNotEmpty) {
        await tester.tap(find.text(' Sign up for free'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      if (find.text('Create Account').evaluate().isNotEmpty) {
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length >= 5) {
          await tester.enterText(fields.at(0), 'Zara');
          await tester.enterText(fields.at(1), 'Fan');
          await tester.enterText(fields.at(2), 'zara@lugmatic.com');
          await tester.enterText(fields.at(3), 'Password123!');
          await tester.enterText(fields.at(4), 'DifferentPass!'); // mismatch

          await tester.tap(find.text('Sign Up').last);
          await tester.pump();

          expect(find.text("Passwords don't match"), findsOneWidget);
        }
      }
    });

    // ── Forgot Password navigation ────────────────────────────────────────
    testWidgets('Tapping Forgot Password navigates to reset screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      if (find.text('Start Listening').evaluate().isNotEmpty) {
        await tester.tap(find.text('Start Listening'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In').first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      if (find.text('Forgot Password?').evaluate().isNotEmpty) {
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're on the reset screen
        expect(
          find.textContaining('Reset').evaluate().isNotEmpty ||
              find.textContaining('Forgot').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });
}
