import '../../../core/network/api_client.dart';

class ContributorService {
  final ApiClient _apiClient;

  ContributorService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch dashboard stats and songs list for contributor.
  Future<Map<String, dynamic>> getContributorDashboard() async {
    try {
      final response = await _apiClient.dio.get('/users/contributor/dashboard');
      final data = response.data;
      return (data['data'] ?? data) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update payout settings for the contributor.
  Future<Map<String, dynamic>> updatePayoutInfo({
    required String method,
    String? paypalEmail,
    Map<String, dynamic>? bankAccount,
    String? stripeAccountId,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/contributor/payout-info',
        data: {
          'method': method,
          if (paypalEmail != null) 'paypalEmail': paypalEmail,
          if (bankAccount != null) 'bankAccount': bankAccount,
          if (stripeAccountId != null) 'stripeAccountId': stripeAccountId,
        },
      );
      final data = response.data;
      return (data['data'] ?? data) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Accept latest terms.
  Future<Map<String, dynamic>> acceptTerms(String version) async {
    try {
      final response = await _apiClient.dio.post(
        '/users/contributor/accept-terms',
        data: {'version': version},
      );
      final data = response.data;
      return (data['data'] ?? data) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
