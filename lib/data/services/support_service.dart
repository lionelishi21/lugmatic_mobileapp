import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class SupportService {
  final ApiClient _apiClient;

  SupportService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> createSupportTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    try {
      final response = await _apiClient.dio.post('/support/tickets', data: {
        'subject': subject,
        'category': category,
        'message': message,
      });
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getTicketHistory() async {
    try {
      final response = await _apiClient.dio.get('/support/tickets');
      final data = response.data;
      return (data['data'] ?? data) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
