import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/comment_model.dart';

class CommentService {
  final ApiClient _apiClient;

  CommentService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<CommentModel>> getComments(String contentType, String contentId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.comments}/$contentType/$contentId',
      );
      final body = response.data;
      final items = body['data'] ?? [];
      return (items as List)
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CommentModel> postComment(String contentType, String contentId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.comments,
        data: {
          'contentType': contentType,
          'contentId': contentId,
          'content': content,
        },
      );
      final body = response.data;
      return CommentModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns the updated (likeCount, isLiked) from the backend.
  Future<(int, bool)> toggleLike(String commentId) async {
    try {
      final response = await _apiClient.dio.post('${ApiConfig.commentLike}/$commentId/like');
      final body = response.data;
      final data = body['data'] ?? body;
      return ((data['likeCount'] as num?)?.toInt() ?? 0, data['isLiked'] as bool? ?? false);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _apiClient.dio.delete('${ApiConfig.comments}/$commentId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
