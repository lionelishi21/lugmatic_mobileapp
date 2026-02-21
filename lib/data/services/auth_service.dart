import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/token_storage.dart';

/// Represents the logged-in user.
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? profilePicture;
  final int coins;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePicture,
    this.coins = 0,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? 'user',
      profilePicture: json['profilePicture'],
      coins: json['coins'] ?? 0,
    );
  }
}

/// Handles all authentication API calls.
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  /// Log in with email/password. Returns the User on success.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      final body = response.data;
      final data = body['data'] ?? body;

      // Save tokens
      final accessToken = data['accessToken'] ?? data['token'];
      final refreshToken = data['refreshToken'];
      if (accessToken != null && refreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      // Parse user from response — backend may nest under 'user' or at top level
      final userData = data['user'] ?? data;
      return User.fromJson(userData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Register a new account.
  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.register,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        },
      );

      final body = response.data;
      final data = body['data'] ?? body;

      final accessToken = data['accessToken'] ?? data['token'];
      final refreshToken = data['refreshToken'];
      if (accessToken != null && refreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      final userData = data['user'] ?? data;
      return User.fromJson(userData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Log in with Google ID token. Returns the User on success.
  Future<User> loginWithGoogle({required String idToken}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.googleAuth,
        data: {'idToken': idToken},
      );

      final body = response.data;
      final data = body['data'] ?? body;

      final accessToken = data['accessToken'] ?? data['token'];
      final refreshToken = data['refreshToken'];
      if (accessToken != null && refreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      final userData = data['user'] ?? data;
      return User.fromJson(userData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Log out — clear local tokens and try to invalidate server-side.
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConfig.logout);
    } catch (_) {
      // Fire-and-forget — clear tokens regardless
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  /// Fetch the currently authenticated user profile.
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.me);
      final body = response.data;
      final data = body['data'] ?? body;
      return User.fromJson(data);
    } on DioException {
      return null;
    }
  }
}
