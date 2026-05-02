import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    if (publishableKey.isEmpty) {
      debugPrint('WARNING: STRIPE_PUBLISHABLE_KEY not set — payments will not work');
      return;
    }
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Returns null on success, or an error message string on failure.
  /// Returns empty string if the user simply cancelled.
  Future<String?> purchaseCoins(int amount) async {
    if (publishableKey.isEmpty) {
      return 'Payment is not configured. Please contact support.';
    }

    try {
      // 1. Create Payment Intent on backend
      final intentData = await _giftService.createPaymentIntent(amount);
      final clientSecret = intentData['clientSecret'] as String?;
      final intentId     = intentData['id']           as String?;
      if (clientSecret == null) return 'Server error: could not create payment. Try again.';

      // 2. Initialise Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          merchantDisplayName: 'Lugmatic',
        ),
      );

      // 3. Present Payment Sheet (throws StripeException on cancel/fail)
      await Stripe.instance.presentPaymentSheet();

      // 4. Verify with backend to credit coins
      if (intentId != null) {
        await _giftService.verifyPurchase(intentId);
      }

      return null; // success
    } on StripeException catch (e) {
      final code = e.error.code;
      // User pressed Cancel — not an error worth showing
      if (code == FailureCode.Canceled) return '';
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      return e.error.localizedMessage ?? 'Payment failed. Please try again.';
    } catch (e) {
      debugPrint('purchaseCoins error: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}
