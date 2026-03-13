import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:lugmatic_flutter/data/services/gift_service.dart';

class StripeService {
  final GiftService _giftService;
  static const String publishableKey = "pk_test_51P2..."; // Replace with real key or move to config

  StripeService({required GiftService giftService}) : _giftService = giftService;

  static Future<void> init() async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<bool> purchaseCoins(int amount) async {
    try {
      // 1. Create Payment Intent on backend
      final intentData = await _giftService.createPaymentIntent(amount);
      final clientSecret = intentData['clientSecret'];

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

      // 4. Verify on backend (optional but recommended if not using webhooks for mobile)
      // await _giftService.verifyPurchase(intentData['id']);

      return true;
    } catch (e) {
      if (e is StripeException) {
        print('Stripe Error: ${e.error.localizedMessage}');
      } else {
        print('Error: $e');
      }
      return false;
    }
  }
}
