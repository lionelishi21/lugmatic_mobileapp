import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // TODO: Replace with your actual RevenueCat API keys
  static const String _appleApiKey = 'YOUR_REVENUECAT_APPLE_API_KEY';
  static const String _googleApiKey = 'YOUR_REVENUECAT_GOOGLE_API_KEY';

  /// Initialize RevenueCat SDK
  static Future<void> init(String appUserId) async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      late PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_googleApiKey)..appUserID = appUserId;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_appleApiKey)..appUserID = appUserId;
      }

      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        await Purchases.configure(configuration);
      }
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  /// Purchase a coin package
  /// [amount] should correspond to a configured product in RevenueCat (e.g., 500 -> 'coin_500')
  Future<String?> purchaseCoins(int amount) async {
    try {
      final productId = 'coin_$amount';
      
      // Attempt to purchase the product
      final CustomerInfo customerInfo = await Purchases.purchaseProduct(productId);
      
      // Since it's a non-renewing consumable, we don't strictly check active entitlements here.
      // RevenueCat's webhook will notify our Node backend to actually grant the coins.
      // Returning null signifies "no error" locally.
      return null;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCat Purchase Error: $e');
        return e.message ?? 'Unknown purchase error';
      }
      return 'cancelled'; // User manually cancelled
    } catch (e) {
      debugPrint('RevenueCat General Error: $e');
      return e.toString();
    }
  }
}
