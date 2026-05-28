import 'dart:developer' as developer;
import '../../models/artist/track_model.dart';
import '../../../core/network/api_client.dart';

class TrackService {
  final ApiClient _apiClient;
  TrackService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Track>> getArtistTracks(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/users/contributor/dashboard');
      final data = response.data;
      final resultData = data['data'];
      final list = resultData != null ? (resultData['songs'] as List? ?? []) : [];
      return list.map((i) => Track.fromJson(i as Map<String, dynamic>)).toList();
    } catch (e) {
      developer.log('Error fetching tracks: $e');
      rethrow;
    }
  }

  Future<TrackAnalytics> getTrackAnalytics(String trackId, {int days = 30}) async {
    try {
      final response = await _apiClient.dio.get('/song/analytics/$trackId?days=$days');
      final data = response.data;
      final json = data['data'] ?? data;
      return TrackAnalytics.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      developer.log('Error fetching track analytics: $e');
      rethrow;
    }
  }

  Future<bool> deleteTrack(String trackId) async {
    try {
      final response = await _apiClient.dio.delete('/song/delete/$trackId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      developer.log('Error deleting track: $e');
      rethrow;
    }
  }
}
