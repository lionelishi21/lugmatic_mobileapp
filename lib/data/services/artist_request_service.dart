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
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.artistRequest,
        data: {
          'artistName': artistName,
          if (genre != null) 'genre': genre,
          if (socialLink != null) 'socialLink': socialLink,
        },
      );
      final body = response.data;
      return ArtistRequestModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
