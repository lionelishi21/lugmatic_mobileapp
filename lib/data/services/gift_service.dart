import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/gift_model.dart';

/// Handles gift browsing, sending, and coin purchases.
class GiftService {
  final ApiClient _apiClient;

  GiftService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all available gifts.
  Future<List<GiftModel>> getGifts() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.gifts);
      final body = response.data;
      final items = body['data'] ?? body;
      return (items as List)
          .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Send a gift to an artist.
  Future<void> sendGift({
    required String artistId,
    required String giftId,
    int quantity = 1,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConfig.sendGift,
        data: {
          'artistId': artistId,
          'giftId': giftId,
          'quantity': quantity,
          if (message != null) 'message': message,
          'isAnonymous': isAnonymous,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Purchase coins with a payment token.
  Future<void> purchaseCoins({
    required int amount,
    required String paymentMethod,
    String? paymentToken,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConfig.purchaseCoins,
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod,
          if (paymentToken != null) 'paymentToken': paymentToken,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
