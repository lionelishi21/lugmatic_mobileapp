import '../../models/artist/dashboard_models.dart';
import '../../../core/network/api_client.dart';

class DashboardService {
  final ApiClient _apiClient;
  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ArtistDetails> getArtistDetails(String artistId) async {
    final response = await _apiClient.dio.get('/artist/details/$artistId');
    final data = response.data;
    final json = data['data'] ?? data;
    return ArtistDetails.fromJson(json as Map<String, dynamic>);
  }

  Future<ArtistStats> getArtistStats(String artistId) async {
    final response = await _apiClient.dio.get('/artist/$artistId/stats');
    final data = response.data;
    final json = data['data'] ?? data;
    return ArtistStats.fromJson(json as Map<String, dynamic>);
  }

  Future<ArtistEarnings> getArtistEarnings() async {
    final response = await _apiClient.dio.get('/finance/earnings');
    final data = response.data;
    final json = data['data'] ?? data;
    return ArtistEarnings.fromJson(json as Map<String, dynamic>);
  }
}
