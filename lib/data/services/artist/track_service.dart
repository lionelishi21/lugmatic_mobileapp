import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/artist/track_model.dart';
import '../../../core/network/api_client.dart';

class TrackService {
  final ApiClient _apiClient;
  TrackService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Track>> getArtistTracks(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/user/contributor/dashboard');
      final data = response.data;
      final resultData = data['data'];
      final list = resultData != null ? (resultData['songs'] as List? ?? []) : [];
      return list.map((i) => Track.fromJson(i as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      developer.log('Error fetching tracks: $e');
      rethrow;
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

  Future<TrackEditDetail> getTrackDetails(String trackId) async {
    try {
      final response = await _apiClient.dio.get('/song/details/$trackId');
      final data = response.data;
      final json = data['data'] ?? data;
      return TrackEditDetail.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      developer.log('Error fetching track details: $e');
      rethrow;
    }
  }

  /// Only usable on a track whose status is 'rejected' — the backend blocks
  /// artists from editing approved/pending tracks. Always resubmits for
  /// review (status -> 'pending', rejectionReason cleared) even when only
  /// metadata changed, so a fixed track doesn't stay invisible forever
  /// waiting on an audio re-upload that never happens.
  Future<void> updateTrack({
    required String trackId,
    required String name,
    required String genreId,
    File? coverArt,
  }) async {
    try {
      final fields = <String, dynamic>{
        'name': name,
        'genre': genreId,
        'status': 'pending',
        'rejectionReason': '',
      };
      if (coverArt != null) {
        fields['coverArt'] = await MultipartFile.fromFile(
          coverArt.path,
          filename: coverArt.path.split('/').last,
        );
      }
      await _apiClient.dio.put(
        '/song/update/$trackId',
        data: FormData.fromMap(fields),
      );
    } catch (e) {
      developer.log('Error updating track: $e');
      rethrow;
    }
  }
}
