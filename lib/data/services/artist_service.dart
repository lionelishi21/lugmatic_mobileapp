import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/artist_model.dart';

/// Fetches artist profiles and related data from the backend.
class ArtistService {
  final ApiClient _apiClient;

  ArtistService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all artists.
  Future<List<ArtistModel>> getArtists({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.artists,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data;
      final items = body['data'] ?? body['artists'] ?? [];
      return (items as List)
          .map((json) => ArtistModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch a single artist by ID.
  Future<ArtistModel> getArtistById(String id) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiConfig.artistDetails}/$id');
      final body = response.data;
      final data = body['data'] ?? body;
      return ArtistModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Follow an artist.
  Future<void> followArtist(String artistId) async {
    try {
      await _apiClient.dio.post(
        '${ApiConfig.mobileArtists}/$artistId/follow',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Unfollow an artist.
  Future<void> unfollowArtist(String artistId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConfig.mobileArtists}/$artistId/follow',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
