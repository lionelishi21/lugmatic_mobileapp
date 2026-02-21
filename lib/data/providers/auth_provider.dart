import 'package:flutter/foundation.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/token_storage.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Manages authentication state across the app.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider({
    required AuthService authService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Check if user has a stored session on app start.
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final hasTokens = await _tokenStorage.hasTokens();
    if (!hasTokens) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Try to fetch current user with stored token
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      await _tokenStorage.clearTokens();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Log in with Google ID token.
  Future<bool> loginWithGoogle({required String idToken}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithGoogle(idToken: idToken);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Log out and clear session.
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear any displayed error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
