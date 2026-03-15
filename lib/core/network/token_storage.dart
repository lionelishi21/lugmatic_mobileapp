import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Securely stores JWT access and refresh tokens using platform keychain/keystore.
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? _initStorage();

  static FlutterSecureStorage _initStorage() {
    try {
      debugPrint('TokenStorage: Initializing storage...');
      // If encryption hangs in release, we can toggle this to false via --dart-define
      const bool useEncryption = bool.fromEnvironment('USE_SECURE_STORAGE', defaultValue: true);
      
      return const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: useEncryption,
          resetOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('TokenStorage: Init failed, falling back: $e');
      return const FlutterSecureStorage();
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  Future<bool> hasTokens() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
