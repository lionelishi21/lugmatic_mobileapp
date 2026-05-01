import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/live_stream_model.dart';
import '../models/live_clash_model.dart';

/// Handles all live-stream related API calls.
class LiveStreamService {
  final ApiClient _apiClient;

  LiveStreamService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch live streams. Uses /active endpoint for live status, /scheduled for upcoming.
  Future<List<LiveStreamModel>> getLiveStreams({String? status}) async {
    try {
      final String endpoint;
      if (status == 'live' || status == 'active') {
        endpoint = '${ApiConfig.liveStreams}/active';
      } else if (status == 'scheduled') {
        endpoint = '${ApiConfig.liveStreams}/scheduled';
      } else {
        endpoint = '${ApiConfig.liveStreams}/active';
      }

      final response = await _apiClient.dio.get(endpoint);

      final body = response.data;
      final data = body['data'] ?? body;

      if (data is List) {
        return data
            .map((json) => LiveStreamModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch a single stream by ID.
  Future<LiveStreamModel> getStream(String streamId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.liveStreamDetails}/$streamId',
      );

      final body = response.data;
      final data = body['data'] ?? body;
      return LiveStreamModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch a LiveKit access token for a stream.
  Future<LiveStreamTokenData> getStreamToken(String streamId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.liveStreamToken}/$streamId/token',
      );

      final body = response.data;
      final data = body['data'] ?? body;
      return LiveStreamTokenData.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Invite an artist to a clash.
  Future<LiveClashModel> inviteToClash(String opponentId, int duration) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.clashInvite,
        data: {
          'opponentArtistId': opponentId,
          'duration': duration,
        },
      );

      final body = response.data;
      final data = body['data'] ?? body;
      return LiveClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Accept a clash invitation.
  Future<LiveClashModel> acceptClash(String clashId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConfig.clash}/$clashId/accept',
      );

      final body = response.data;
      final data = body['data'] ?? body;
      return LiveClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Reject a clash invitation.
  Future<void> rejectClash(String clashId) async {
    try {
      await _apiClient.dio.post(
        '${ApiConfig.clash}/$clashId/reject',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get a LiveKit token for the shared clash room (viewer or host).
  Future<Map<String, dynamic>> getClashToken(String clashId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.clash}/$clashId/token');
      return (response.data['data'] ?? response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update the clash realm (only participants can do this).
  Future<void> updateClashRealm(String clashId, String realm) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConfig.clash}/$clashId/realm',
        data: {'realm': realm},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get clash details.
  Future<LiveClashModel> getClashDetails(String clashId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.clashDetails}/$clashId',
      );

      final body = response.data;
      final data = body['data'] ?? body;
      return LiveClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get clash rankings.
  Future<List<Map<String, dynamic>>> getClashRankings(String period) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.clashRankings,
        queryParameters: {'period': period},
      );

      final body = response.data;
      final data = body['data'] ?? body;
      if (data is List) {
        return data.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get recent clashes for the public feed.
  Future<List<LiveClashModel>> getRecentClashes({int limit = 10, int skip = 0}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.clashList,
        queryParameters: {'limit': limit, 'skip': skip},
      );

      final body = response.data;
      final data = body['data'] ?? [];
      if (data is List) {
        return data
            .map((json) => LiveClashModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get recorded streams (VOD).
  Future<List<LiveStreamModel>> getRecordedStreams({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.liveStreamRecorded,
        queryParameters: {'page': page, 'limit': limit},
      );

      final body = response.data;
      final data = body['data'] ?? body;

      if (data is List) {
        return data
            .map((json) => LiveStreamModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Create a new live stream (pre-setup).
  Future<LiveStreamModel> createStream({required String title, String? description, String? category}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.liveStreams,
        data: {
          'title': title,
          'description': description ?? '',
          'category': category ?? 'Entertainment',
        },
      );
      final body = response.data;
      final data = body['data'] ?? body;
      return LiveStreamModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Start a previously created stream.
  Future<void> startStream(String streamId) async {
    try {
      await _apiClient.dio.put('${ApiConfig.liveStreams}/$streamId/start');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// End a live stream.
  Future<void> endStream(String streamId) async {
    try {
      await _apiClient.dio.put('${ApiConfig.liveStreams}/$streamId/end');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
