import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessageService {
  final ApiClient _apiClient;

  MessageService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.conversations);
      final body = response.data;
      final items = body['data'] ?? body;
      return (items as List)
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.messages}/$conversationId');
      final body = response.data;
      final items = body['data'] ?? body;
      return (items as List)
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ConversationModel> startConversation(String artistId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.startConversation,
        data: {'artistId': artistId},
      );
      final body = response.data;
      final data = body['data'] ?? body;
      return ConversationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConfig.messages}/$conversationId',
        data: {'content': content},
      );
      final body = response.data;
      final data = body['data'] ?? body;
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.dio.put('${ApiConfig.markMessageRead}/$conversationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.messageUnreadCount);
      final body = response.data;
      return (body['data']?['count'] ?? body['count'] ?? 0) as int;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
