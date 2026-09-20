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

  /// Purchase coins using RevenueCat. Coins are credited server-side by the
  /// RevenueCat webhook (NON_RENEWING_PURCHASE event) once it fires — there
  /// is no separate client-driven sync call. (There used to be one here,
  /// but it posted to ApiConfig.purchaseCoins, which is actually the
  /// PayPal-order-creation endpoint — a completely different shape and
  /// purpose — so it always failed and was silently swallowed.) Callers
  /// should poll getCoinBalance() after this resolves; see
  /// pollForBalanceIncrease below.
  Future<CustomerInfo?> purchaseCoins(Package package) {
    return _revenueCatService.purchasePackage(package);
  }

  /// Polls the coin balance a few times after a purchase, since crediting
  /// happens async via webhook and isn't guaranteed to have landed the
  /// instant the store confirms the charge. Returns the new balance once it
  /// increases past [previousBalance], or null if it hasn't landed within
  /// the polling window (the purchase still succeeded — the balance will
  /// catch up once the webhook lands; callers should say so, not claim
  /// failure).
  Future<int?> pollForBalanceIncrease(
    int previousBalance, {
    int attempts = 5,
    Duration interval = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < attempts; i++) {
      await Future.delayed(interval);
      try {
        final balanceData = await getCoinBalance();
        final coins = balanceData['coins'] as int?;
        if (coins != null && coins > previousBalance) return coins;
      } catch (_) {
        // Keep polling — a transient failure here shouldn't abort the wait.
      }
    }
    return null;
  }
}
