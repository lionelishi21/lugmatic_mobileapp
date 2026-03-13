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

  /// Search songs, artists, and albums.
  Future<List<MusicModel>> searchSongs(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.search,
        queryParameters: {'q': query},
      );
      final body = response.data;
      final data = body['data'] ?? body;
      final results = data['songs'] ?? [];
      return (results as List)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Toggle favorite status for a song.
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      if (isFavorite) {
        await _apiClient.dio.post('${ApiConfig.mobileFavorites}/song/$id');
      } else {
        await _apiClient.dio.delete('${ApiConfig.mobileFavorites}/song/$id');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch related songs for a given song (using genre as a recommendation signal).
  Future<List<MusicModel>> getRelatedSongs(String genre, {String? excludeId}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'genre': genre, 'limit': 10},
      );
      final body = response.data;
      final items = body['data'] ?? body['songs'] ?? [];
      final songs = (items as List)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (excludeId != null) {
        songs.removeWhere((s) => s.id == excludeId);
      }
      return songs;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
