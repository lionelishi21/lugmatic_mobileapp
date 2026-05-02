import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/video_model.dart';

/// Fetches video content and details from the backend.
class VideoService {
  final ApiClient _apiClient;

  VideoService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all videos (paginated/list).
  Future<List<VideoModel>> getVideos({String? artistId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (artistId != null) queryParams['artist'] = artistId;

      final response = await _apiClient.dio.get(
        ApiConfig.videos,
        queryParameters: queryParams,
      );
      final body = response.data;
      final rawData = body['data'];
      final items = rawData is List ? rawData : rawData?['videos'] ?? body['videos'] ?? [];
      return (items as List)
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch discovery feed videos. Falls back to all videos if feed is empty.
  Future<List<VideoModel>> getFeedVideos() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.videoFeed);
      final body = response.data;
      final rawData = body['data'];
      final items = rawData is List ? rawData : rawData?['videos'] ?? body['videos'] ?? [];
      final videos = (items as List)
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (videos.isNotEmpty) return videos;
      // Feed is empty — fall back to all videos
      return getVideos();
    } on DioException catch (e) {
      // Feed endpoint failed — try all videos
      try {
        return getVideos();
      } catch (_) {
        throw ApiException.fromDioException(e);
      }
    }
  }

  /// Fetch a single video by ID.
  Future<VideoModel> getVideoById(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.videoDetails}/$id');
      final body = response.data;
      final data = body['data'] ?? body;
      return VideoModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch video specifically tied to a song.
  Future<VideoModel?> getVideoBySong(String songId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.songVideos}/$songId');
      final body = response.data;
      if (body['success'] == true && body['data'] != null) {
        return VideoModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      // If 404, just return null as it's common for songs to not have videos
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  /// Increment view count for a video.
  Future<void> incrementViews(String id) async {
    try {
      await _apiClient.dio.post('${ApiConfig.videoView}/$id');
    } catch (e) {
      // Silent fail for view counts
    }
  }
}
