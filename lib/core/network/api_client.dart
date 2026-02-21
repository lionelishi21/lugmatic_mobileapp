import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

/// Central Dio HTTP client with auth interceptor and token refresh.
class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(tokenStorage: _tokenStorage, dio: dio),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }
}

/// Attaches the access token and handles 401 -> token refresh.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor({required TokenStorage tokenStorage, required Dio dio})
      : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Use a fresh Dio instance (no interceptors) to avoid loops
        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ));

        final response = await refreshDio.post(
          ApiConfig.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        final newAccess = response.data['accessToken'] as String?;
        final newRefresh = response.data['refreshToken'] as String?;

        if (newAccess != null && newRefresh != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );

          // Retry the original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await _dio.fetch(options);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await _tokenStorage.clearTokens();
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}

/// Debug-only request/response logger.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}
