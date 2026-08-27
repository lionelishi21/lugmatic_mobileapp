import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/config/api_config.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();

  factory RevenueCatService() {
    return _instance;
  }

  RevenueCatService._internal();

  bool _isInitialized = false;

  /// Initialize the RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    late PurchasesConfiguration configuration;

    if (Platform.isAndroid) {
      if (ApiConfig.revenuecatGoogleKey.isEmpty) {
        debugPrint('RevenueCat Google Key is missing');
        return;
      }
      configuration = PurchasesConfiguration(ApiConfig.revenuecatGoogleKey);
    } else if (Platform.isIOS) {
      if (ApiConfig.revenuecatAppleKey.isEmpty) {
        debugPrint('RevenueCat Apple Key is missing');
        return;
      }
      configuration = PurchasesConfiguration(ApiConfig.revenuecatAppleKey);
    } else {
      debugPrint('RevenueCat is not supported on this platform.');
      return;
    }

    await Purchases.configure(configuration);
    _isInitialized = true;
  }

  /// Log in to RevenueCat with an app user ID (e.g., from your backend)
  Future<void> login(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
    }
  }

  /// Log out of RevenueCat
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
    }
  }

  /// Fetch all available offerings configured in RevenueCat dashboard
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to get RevenueCat offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      debugPrint('Failed to purchase package: $e');
      throw e;
    }
  }

  /// Get current customer info (for checking active subscriptions)
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Failed to get customer info: $e');
      return null;
    }
  }

  /// Restore previous purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      return null;
    }
  }

  /// Check if a user has a specific active entitlement
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    final customerInfo = await getCustomerInfo();
    if (customerInfo == null) return false;
    return customerInfo.entitlements.all[entitlementId]?.isActive == true;
  }
}
