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
          'opponentId': opponentId,
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
        '${ApiConfig.clashAccept}/$clashId',
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
        '${ApiConfig.clashReject}/$clashId',
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
}
