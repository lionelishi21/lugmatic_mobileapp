import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/music_model.dart';
import '../models/artist_model.dart';
import '../models/podcast_model.dart';
import '../models/gift_model.dart';

class HomeService {
  final ApiClient _apiClient;

  HomeService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch trending songs from the backend.
  Future<List<MusicModel>> getTrendingSongs() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'limit': 20, 'sort': '-playCount'},
      );
      final body = response.data;
      final items = body['data'] ?? body['songs'] ?? [];
      return (items as List)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch featured artists from the backend.
  Future<List<ArtistModel>> getFeaturedArtists() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.artists,
        queryParameters: {'limit': 20},
      );
      final body = response.data;
      final items = body['data'] ?? body['artists'] ?? [];
      return (items as List)
          .map((json) => ArtistModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch featured podcasts from the backend.
  Future<List<PodcastModel>> getFeaturedPodcasts() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.podcasts,
        queryParameters: {'limit': 10},
      );
      final body = response.data;
      final items = body['data'] ?? body['podcasts'] ?? [];
      return (items as List)
          .map((json) => PodcastModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch available gifts from the backend.
  Future<List<GiftModel>> getPopularGifts() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.gifts);
      final body = response.data;
      final items = body['data'] ?? body;
      if (items is List) {
        return items
            .where((g) => g['isActive'] == true)
            .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch recommended playlists from the backend.
  Future<List<Map<String, dynamic>>> getRecommendedPlaylists() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.playlists,
        queryParameters: {'recommended': true, 'limit': 10},
      );
      final body = response.data;
      final items = body['data'] ?? body['playlists'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      return [];
    }
  }
}
