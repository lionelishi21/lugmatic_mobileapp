import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/gift_model.dart';

/// Handles gift browsing, sending, and coin purchases.
class GiftService {
  final ApiClient _apiClient;

  GiftService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch user coin balance.
  Future<Map<String, dynamic>> getCoinBalance() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.coinBalance);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  /// Create a payment intent for native Stripe payments.
  Future<Map<String, dynamic>> createPaymentIntent(int amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.createPaymentIntent,
        data: {'amount': amount},
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Purchase coins with a payment token (legacy/manual).
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

  /// Create a PayPal order for a coin purchase. Returns the orderId and the
  /// PayPal approval URL to open in a WebView — the user approves there, then
  /// the app calls [capturePaypalOrder] to finish the purchase.
  Future<({String orderId, String? approveUrl})> createPaypalCoinOrder(int amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.purchaseCoins,
        data: {'amount': amount},
      );
      final data = response.data['data'];
      final orderId = data?['orderId'] as String?;
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Failed to create PayPal order');
      }
      return (orderId: orderId, approveUrl: data?['approveUrl'] as String?);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Capture an approved PayPal order — this is what actually credits the coins.
  Future<Map<String, dynamic>> capturePaypalOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.paypalCaptureOrder,
        data: {'orderId': orderId},
      );
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Verify a completed Stripe payment intent and credit coins to the user.
  Future<Map<String, dynamic>> verifyPurchase(String paymentIntentId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.verifyPurchase,
        data: {'paymentIntentId': paymentIntentId},
      );
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
