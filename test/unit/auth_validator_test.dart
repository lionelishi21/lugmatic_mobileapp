import 'package:flutter_test/flutter_test.dart';
import 'package:lugmatic_flutter/features/auth/utils/auth_validator.dart';
import 'package:lugmatic_flutter/core/constants/app_strings.dart';

void main() {
  group('AuthValidator.validateEmail', () {
    test('returns error when email is null', () {
      expect(
        AuthValidator.validateEmail(null),
        AppStrings.emailRequired,
      );
    });

    test('returns error when email is empty', () {
      expect(
        AuthValidator.validateEmail(''),
        AppStrings.emailRequired,
      );
    });

    test('returns error when email has no @ symbol', () {
      expect(
        AuthValidator.validateEmail('notanemail'),
        AppStrings.emailInvalid,
      );
    });

    test('returns error when email is missing domain', () {
      expect(
        AuthValidator.validateEmail('user@'),
        AppStrings.emailInvalid,
      );
    });

    test('returns error when email is missing TLD', () {
      expect(
        AuthValidator.validateEmail('user@domain'),
        AppStrings.emailInvalid,
      );
    });

    test('returns null for a valid email', () {
      expect(AuthValidator.validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(AuthValidator.validateEmail('fan@mail.lugmatic.com'), isNull);
    });

    test('returns null for email with + alias', () {
      expect(AuthValidator.validateEmail('fan+test@example.com'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthValidator.validatePassword', () {
    test('returns error when password is null', () {
      expect(
        AuthValidator.validatePassword(null),
        AppStrings.passwordRequired,
      );
    });

    test('returns error when password is empty', () {
      expect(
        AuthValidator.validatePassword(''),
        AppStrings.passwordRequired,
      );
    });

    test('returns error when password is fewer than 8 characters', () {
      expect(
        AuthValidator.validatePassword('abc1234'),
        AppStrings.passwordTooShort,
      );
    });

    test('returns null for a password of exactly 8 characters', () {
      expect(AuthValidator.validatePassword('abcd1234'), isNull);
    });

    test('returns null for a long valid password', () {
      expect(AuthValidator.validatePassword('MyS3cur3P@ssword!'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthValidator.validateConfirmPassword', () {
    test('returns error when confirm password is null', () {
      expect(
        AuthValidator.validateConfirmPassword(null, 'password'),
        AppStrings.passwordRequired,
      );
    });

    test('returns error when confirm password is empty', () {
      expect(
        AuthValidator.validateConfirmPassword('', 'password'),
        AppStrings.passwordRequired,
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        AuthValidator.validateConfirmPassword('different', 'password'),
        AppStrings.passwordsDontMatch,
      );
    });

    test('returns null when passwords match', () {
      expect(
        AuthValidator.validateConfirmPassword('password123', 'password123'),
        isNull,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('AuthValidator.validateName', () {
    test('returns error when name is null', () {
      expect(
        AuthValidator.validateName(null),
        AppStrings.nameRequired,
      );
    });

    test('returns error when name is empty', () {
      expect(
        AuthValidator.validateName(''),
        AppStrings.nameRequired,
      );
    });

    test('returns error when name is a single character', () {
      expect(
        AuthValidator.validateName('A'),
        isNotNull,
      );
    });

    test('returns null for a valid name', () {
      expect(AuthValidator.validateName('Leon'), isNull);
    });

    test('returns null for a two-character name', () {
      expect(AuthValidator.validateName('Jo'), isNull);
    });
  });
}
