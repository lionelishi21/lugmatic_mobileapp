// Smoke test placeholder.
//
// LugmaticApp requires a real Firebase environment (native platform channels
// for Firebase Core, Messaging, and Secure Storage) which cannot be initialised
// in the headless `flutter test` runner. Attempting to pump the full widget
// tree leaves pending timers that the AutomatedTestWidgetsFlutterBinding
// treats as a hard failure.
//
// Full auth + UI coverage is provided by:
//   • test/unit/auth_validator_test.dart   — 21 cases
//   • test/unit/auth_provider_test.dart    — 14 cases
//   • test/widget/login_screen_test.dart   — 12 cases
//   • test/widget/signup_screen_test.dart  — 12 cases

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('(placeholder — see test/unit/ and test/widget/ for coverage)', () {
    // Nothing to do here.
  });
}
