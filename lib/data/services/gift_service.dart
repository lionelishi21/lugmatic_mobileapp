import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/gift_model.dart';
import 'revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Handles gift browsing, sending, and coin purchases.
class GiftService {
  final ApiClient _apiClient;
  final RevenueCatService _revenueCatService = RevenueCatService();

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

  /// Get coin packages from RevenueCat
  Future<List<Package>> getCoinPackages() async {
    final offerings = await _revenueCatService.getOfferings();
    if (offerings != null && offerings.all.containsKey('coins')) {
      return offerings.all['coins']!.availablePackages;
    }
    // Fallback to current offering if 'coins' offering is not explicitly named
    if (offerings != null && offerings.current != null) {
      return offerings.current!.availablePackages.where((p) => p.identifier.contains('coin')).toList();
    }
    return [];
  }

  /// Purchase coins using RevenueCat
  Future<CustomerInfo?> purchaseCoins(Package package) async {
    final customerInfo = await _revenueCatService.purchasePackage(package);
    
    // If purchase was successful, notify the backend to grant the coins
    if (customerInfo != null && customerInfo.entitlements.all.isNotEmpty) {
      try {
        await _apiClient.dio.post(
          ApiConfig.purchaseCoins,
          data: {
            'packageId': package.identifier,
            'rcUserId': customerInfo.originalAppUserId,
          },
        );
      } catch (e) {
        // Log the error but don't fail the whole flow if the backend sync is delayed.
        // In a production app, you might want a retry queue for this.
        print('Backend sync for coin purchase failed: $e');
      }
    }
    
    return customerInfo;
  }
}
