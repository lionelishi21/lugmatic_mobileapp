import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/clash_pool_model.dart';
import '../models/regular_clash_model.dart';

class RegularClashService {
  final ApiClient _apiClient;

  RegularClashService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ClashPoolModel>> getActivePools() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.regularClashPools);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((j) => ClashPoolModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getPool(String poolId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.regularClashPool}/$poolId');
      final data = response.data['data'] ?? response.data;
      final pool = ClashPoolModel.fromJson(data['pool'] as Map<String, dynamic>);
      final clashes = (data['clashes'] as List? ?? [])
          .map((j) => RegularClashModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return {'pool': pool, 'clashes': clashes};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RegularClashModel>> getClashFeed({String? status, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null) params['status'] = status;
      final response = await _apiClient.dio.get(
        ApiConfig.regularClashFeed,
        queryParameters: params,
      );
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((j) => RegularClashModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RegularClashModel> getClash(String clashId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.regularClashBase}/$clashId');
      final data = response.data['data'] ?? response.data;
      return RegularClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RegularClashModel> sendChallenge({
    required String poolId,
    required String opponentArtistId,
    String realm = 'fire',
    String? rhythmId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.regularClashChallenge,
        data: {
          'poolId': poolId,
          'opponentArtistId': opponentArtistId,
          'realm': realm,
          if (rhythmId != null) 'rhythmId': rhythmId,
          if (message != null) 'message': message,
        },
      );
      final data = response.data['data'] ?? response.data;
      return RegularClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RegularClashModel> acceptChallenge(String clashId) async {
    try {
      final response = await _apiClient.dio.post('${ApiConfig.regularClashBase}/$clashId/accept');
      final data = response.data['data'] ?? response.data;
      return RegularClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> rejectChallenge(String clashId) async {
    try {
      await _apiClient.dio.post('${ApiConfig.regularClashBase}/$clashId/reject');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RegularClashModel> submitVideo(
    String clashId, {
    required String videoUrl,
    required String videoKey,
    String? thumbnailUrl,
    required int duration,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConfig.regularClashBase}/$clashId/submit-video',
        data: {
          'videoUrl': videoUrl,
          'videoKey': videoKey,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
          'duration': duration,
        },
      );
      final data = response.data['data'] ?? response.data;
      return RegularClashModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RegularClashModel>> getMyClashes() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.regularClashMyClashes);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((j) => RegularClashModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RegularClashModel>> getIncomingChallenges() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.regularClashIncoming);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((j) => RegularClashModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> vote(String clashId, String side) async {
    try {
      await _apiClient.dio.post(
        '${ApiConfig.regularClashBase}/$clashId/vote',
        data: {'side': side},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> like(String clashId) async {
    try {
      await _apiClient.dio.post('${ApiConfig.regularClashBase}/$clashId/like');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
