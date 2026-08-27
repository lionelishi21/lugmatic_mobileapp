import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/subscription_plan_model.dart';
import 'revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  final ApiClient _apiClient;
  final RevenueCatService _revenueCatService = RevenueCatService();

  SubscriptionService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch available subscription plans from RevenueCat.
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      if (offerings != null && offerings.current != null) {
        final currentOffering = offerings.current!;
        return currentOffering.availablePackages.map((package) {
          final isPopular = package.identifier.contains('popular') || package.identifier.contains('premium_monthly');
          return SubscriptionPlan(
            id: package.identifier,
            name: package.storeProduct.title,
            description: package.storeProduct.description,
            price: package.storeProduct.price,
            interval: package.packageType == PackageType.annual ? 'year' : 'month',
            features: [
              'Ad-free music',
              'Hi-Fi Audio Quality',
              'Offline downloads',
              if (package.packageType == PackageType.annual) 'Everything in Monthly',
            ],
            isPopular: isPopular,
            rcPackage: package,
          );
        }).toList();
      }
      return _getHardcodedPlans();
    } catch (e) {
      return _getHardcodedPlans();
    }
  }

  /// Purchase a subscription plan using RevenueCat.
  Future<CustomerInfo?> purchaseSubscription(SubscriptionPlan plan) async {
    if (plan.rcPackage == null) {
      throw Exception('Invalid package for purchase');
    }
    return await _revenueCatService.purchasePackage(plan.rcPackage);
  }

  List<SubscriptionPlan> _getHardcodedPlans() {
    return [
      SubscriptionPlan(
        id: 'free',
        name: 'Basic',
        description: 'Enjoy music with occasional interruptions.',
        price: 0,
        interval: 'month',
        features: ['Ad-supported listening', 'Standard audio quality', 'Online play only'],
      ),
      SubscriptionPlan(
        id: 'premium_monthly',
        name: 'Premium Monthly',
        description: 'The full experience with zero interruptions.',
        price: 9.99,
        interval: 'month',
        features: ['Ad-free music', 'Hi-Fi Audio Quality', 'Offline downloads', 'Unlimited Skips'],
        isPopular: true,
      ),
      SubscriptionPlan(
        id: 'premium_yearly',
        name: 'Premium Annual',
        description: 'Best value for year-round music lovers.',
        price: 99.99,
        interval: 'year',
        features: ['Everything in Monthly', '2 months free', 'Exclusive badge'],
      ),
    ];
  }
}
