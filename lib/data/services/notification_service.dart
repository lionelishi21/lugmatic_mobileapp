import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.notifications);
      final body = response.data;
      final items = body['data'] ?? [];
      return (items as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.put(ApiConfig.markRead);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConfig.notifications}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _apiClient.dio.post(ApiConfig.fcmToken, data: {'fcmToken': token});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
