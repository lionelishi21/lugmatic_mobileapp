import '../../../../core/network/api_client.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  final ApiClient apiClient;

  PlaylistService({required this.apiClient});

  Future<List<PlaylistModel>> getUserPlaylists() async {
    try {
      final response = await apiClient.dio.get('/playlist/my/list');
      final List data = response.data['data'] ?? [];
      return data.map((json) => PlaylistModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    List<String> songs = const [],
  }) async {
    try {
      final response = await apiClient.dio.post('/playlist/my/create', data: {
        'name': name,
        'description': description ?? '',
        'songs': songs,
      });
      return PlaylistModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<PlaylistModel> copyPlaylist(String playlistId) async {
    try {
      final response = await apiClient.dio.post('/playlist/my/$playlistId/copy');
      return PlaylistModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await apiClient.dio.post('/playlist/my/$playlistId/add-song', data: {
        'songId': songId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await apiClient.dio.delete('/playlist/my/$playlistId/remove-song', data: {
        'songId': songId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await apiClient.dio.delete('/playlist/my/delete/$playlistId');
    } catch (e) {
      rethrow;
    }
  }

  Future<PlaylistModel> getPlaylistDetails(String playlistId) async {
    try {
      final response = await apiClient.dio.get('/playlist/details/$playlistId');
      return PlaylistModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
