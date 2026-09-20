import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// Single entry point for favoriting/unfavoriting any type the backend's
/// unified favorites endpoint supports (song, artist, album, playlist).
class FavoritesService {
  final ApiClient _apiClient;

  FavoritesService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> setFavorite({
    required String type,
    required String id,
    required bool favorited,
  }) async {
    try {
      if (favorited) {
        await _apiClient.dio.post('${ApiConfig.mobileFavorites}/$type/$id');
      } else {
        await _apiClient.dio.delete('${ApiConfig.mobileFavorites}/$type/$id');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
