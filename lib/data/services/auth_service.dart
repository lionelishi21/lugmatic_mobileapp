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
  final List<String> roles;
  final String? profilePicture;
  final int coins;
  final bool isArtist;
  final bool isContributor;
  final String? artistId;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.roles = const ['user'],
    this.profilePicture,
    this.coins = 0,
    this.isArtist = false,
    this.isContributor = false,
    this.artistId,
  });

  String get fullName => '$firstName $lastName';

  bool get hasArtistRole =>
      roles.contains('artist') || isArtist || role == 'artist';
  bool get hasContributorRole =>
      roles.contains('contributor') || isContributor;
  bool get hasProviderRole =>
      roles.contains('provider') || role == 'provider';
  bool get hasAdminRole =>
      roles.contains('admin') || roles.contains('super admin') ||
      role == 'admin' || role == 'super admin';

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final rolesList = rawRoles is List
        ? List<String>.from(rawRoles)
        : [json['role'] as String? ?? 'user'];

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? 'user',
      roles: rolesList,
      profilePicture: json['profilePicture'],
      coins: json['coins'] ?? 0,
      isArtist: json['isArtist'] ?? false,
      isContributor: json['isContributor'] ?? false,
      artistId: json['artistId'],
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

  /// Returns the stored access token (used by services that need raw bearer auth).
  Future<String?> getToken() => _tokenStorage.getAccessToken();

  /// Log in with email/password. Returns the User on success.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password, 'deviceType': 'mobile'},
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
        data: {'idToken': idToken, 'deviceType': 'mobile'},
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

  /// Add a role (artist or contributor) to the current user.
  /// Re-issues JWT with updated roles and returns the refreshed User.
  Future<User> addRole(String role) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.addRole,
        data: {'role': role},
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

  /// Send a password reset email.
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Verify email with code/token.
  Future<void> verifyEmail(String token) async {
    try {
      await _apiClient.dio.post(
        ApiConfig.verifyEmail,
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
