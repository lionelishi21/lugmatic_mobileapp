import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/music_model.dart';

/// Fetches songs, search results, and streaming data from the backend.
class MusicService {
  final ApiClient _apiClient;

  MusicService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all songs (paginated).
  Future<List<MusicModel>> getSongs({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data;
      final items = body['data'] ?? body['songs'] ?? [];
      return (items as List)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch a single song by ID.
  Future<MusicModel> getSongById(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.songDetails}/$id');
      final body = response.data;
      final data = body['data'] ?? body;
      return MusicModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Search songs.
  Future<List<MusicModel>> searchSongs(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.mobileSearch,
        queryParameters: {'q': query, 'type': 'song'},
      );
      final body = response.data;
      final results = body['data']?['songs'] ?? [];
      return (results as List)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
