import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/artist_request_model.dart';

class ArtistRequestService {
  final ApiClient _apiClient;

  ArtistRequestService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ArtistRequestModel> submitRequest({
    required String artistName,
    String? genre,
    String? socialLink,
    String requestType = 'new_artist',
    String? claimedArtistId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.artistRequest,
        data: {
          'artistName': artistName,
          if (genre != null) 'genre': genre,
          if (socialLink != null) 'socialLink': socialLink,
          'requestType': requestType,
          if (claimedArtistId != null) 'claimedArtistId': claimedArtistId,
        },
      );
      final body = response.data;
      return ArtistRequestModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Request to claim an unclaimed (label-managed) artist profile.
  Future<ArtistRequestModel> claimProfile({
    required String artistId,
    required String artistName,
  }) {
    return submitRequest(
      artistName: artistName,
      requestType: 'claim_profile',
      claimedArtistId: artistId,
    );
  }

  Future<List<ArtistRequestModel>> getMyRequests() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.myArtistRequests);
      final body = response.data;
      final items = body['data'] ?? [];
      return (items as List)
          .map((json) => ArtistRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
