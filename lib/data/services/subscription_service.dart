import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionService {
  final ApiClient _apiClient;

  SubscriptionService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch available subscription plans.
  /// Note: Falls back to hardcoded defaults if API fails or returns empty.
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      // Trying to fetch from admin plans if available, or a dedicated public endpoint
      // For now, we'll try the dedicated endpoint or use defaults.
      final response = await _apiClient.dio.get('/subscription/plans').catchError((_) => 
        _apiClient.dio.get('/admin/subscription-plans')
      );
      
      final body = response.data;
      final items = body['data'] ?? body;
      
      if (items is List && items.isNotEmpty) {
        return items.map((json) => SubscriptionPlan.fromJson(json)).toList();
      }
      return _getHardcodedPlans();
    } catch (e) {
      return _getHardcodedPlans();
    }
  }

  /// Create a subscription payment intent.
  Future<Map<String, dynamic>> createSubscriptionIntent(String planId) async {
    try {
      final response = await _apiClient.dio.post(
        '/subscription/create-intent',
        data: {'planId': planId},
      );
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
