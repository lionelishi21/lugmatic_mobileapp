import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/music_model.dart';
import '../models/artist_model.dart';
import '../models/podcast_model.dart';
import '../models/gift_model.dart';

class HomeService {
  final ApiClient _apiClient;

  HomeService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Parse the data list from an API response body.
  /// Handles both {success, data: [...]} and raw [...] responses.
  List _extractList(dynamic body, List<String> keys) {
    if (body is List) return body;
    for (final key in keys) {
      final val = body[key];
      if (val is List) return val;
    }
    return [];
  }

  /// Fetch trending songs from the backend.
  Future<List<MusicModel>> getTrendingSongs() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'limit': 20, 'sort': '-playCount'},
      );
      final items = _extractList(response.data, ['data', 'songs']);
      return (items)
          .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch new releases from the backend.
  Future<List<MusicModel>> getNewReleases() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'limit': 20, 'sort': '-releaseDate'},
      );
      final items = _extractList(response.data, ['data', 'songs']);
      return (items)
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
        ApiConfig.mobileArtists,
        queryParameters: {'limit': 20, 'featured': 'true'},
      );
      // /mobile/artists returns { success: true, data: { items: [...], nextCursor: ... } }
      final items = _extractList(response.data, ['data', 'items']);
      return (items)
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
      final items = _extractList(response.data, ['data', 'podcasts']);
      return (items)
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
      final items = _extractList(body, ['data', 'gifts']);
      return items
          .where((g) => g['isActive'] == true)
          .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
      final items = _extractList(response.data, ['data', 'playlists']);
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      return [];
    }
  }
}
