import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/live_stream_model.dart';

/// Handles all live-stream related API calls.
class LiveStreamService {
  final ApiClient _apiClient;

  LiveStreamService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch live streams, optionally filtered by status.
  Future<List<LiveStreamModel>> getLiveStreams({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.dio.get(
        ApiConfig.liveStreams,
        queryParameters: queryParams,
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
}
