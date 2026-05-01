import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:lugmatic_flutter/data/services/gift_service.dart';

class StripeService {
  final GiftService _giftService;

  // Set via --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_... at build time
  static const String publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  StripeService({required GiftService giftService}) : _giftService = giftService;

  static Future<void> init() async {
    assert(publishableKey.isNotEmpty, 'STRIPE_PUBLISHABLE_KEY must be set via --dart-define');
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<bool> purchaseCoins(int amount) async {
    try {
      // 1. Create Payment Intent on backend
      final intentData = await _giftService.createPaymentIntent(amount);
      final clientSecret = intentData['clientSecret'] as String?;
      final intentId = intentData['id'] as String?;
      if (clientSecret == null) throw Exception('Missing clientSecret from server');

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          merchantDisplayName: 'Lugmatic',
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Verify with backend so coins are credited (idempotent — safe to call even if webhook fires first)
      if (intentId != null) {
        await _giftService.verifyPurchase(intentId);
      }

      return true;
    } catch (e) {
      if (e is StripeException) {
        debugPrint('Stripe Error: ${e.error.localizedMessage}');
      } else {
        debugPrint('Stripe purchase error: $e');
      }
      return false;
    }
  }
}
