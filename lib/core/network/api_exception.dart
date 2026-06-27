import 'package:dio/dio.dart';

/// A user-friendly exception parsed from Dio errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to server. Please try again later.',
        );
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final statusCode = e.response?.statusCode;
        String message = 'Something went wrong';

        if (data is Map<String, dynamic>) {
          message = data['message'] as String? ?? message;
          // Many endpoints return a generic message + a separate `error` field
          // with the actual root cause (e.g. "PayPal is not configured...").
          // Surface both so failures are actually debuggable instead of just
          // showing a generic "Something went wrong" / "Error purchasing coins".
          final detail = data['error'] as String?;
          if (detail != null && detail.isNotEmpty && detail != message) {
            message = '$message: $detail';
          }
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled');
      default:
        return ApiException(
          message: e.message ?? 'An unexpected error occurred',
        );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
