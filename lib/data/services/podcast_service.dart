import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/podcast_model.dart';

/// Fetches podcasts and episodes from the backend.
class PodcastService {
  final ApiClient _apiClient;

  PodcastService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all podcasts, optionally filtered by search query and/or category.
  Future<List<PodcastModel>> getPodcasts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.podcasts,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final body = response.data;
      final items = body['data'] ?? body['podcasts'] ?? [];
      return (items as List)
          .map((json) => PodcastModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch trending podcasts.
  Future<List<PodcastModel>> getTrendingPodcasts({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.podcastTrending,
        queryParameters: {'limit': limit},
      );
      final body = response.data;
      final items = body['data'] ?? body['podcasts'] ?? [];
      return (items as List)
          .map((json) => PodcastModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch a single podcast by ID.
  Future<PodcastModel> getPodcastById(String id) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiConfig.podcasts}/$id');
      final body = response.data;
      final data = body['data'] ?? body;
      return PodcastModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
