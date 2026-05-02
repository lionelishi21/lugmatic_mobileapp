import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ManagementService {
  final ApiClient _apiClient;

  ManagementService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ── Admin Endpoints ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.adminDashboard);
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getAdminUsers({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.adminUsers,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getAdminArtists({int page = 1, String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.adminArtists,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
          'isApproved': 'false', // Focus on pending approvals for now
        },
      );
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getContentForModeration(String type) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.adminModeration}/$type');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> moderateContent(String type, String id, String action, String? reason) async {
    try {
      await _apiClient.dio.put(
        '${ApiConfig.adminModeration}/$type/$id',
        data: {'action': action, 'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> reviewArtist(String artistId, bool approved, String? reason) async {
    try {
      await _apiClient.dio.put(
        '${ApiConfig.adminArtists}/$artistId/approve',
        data: {'approved': approved, 'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Artist Endpoints ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getArtistStats(String artistId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.artistStats}/$artistId/stats');
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getArtistSongs(String artistId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.artistStats}/$artistId/songs');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
