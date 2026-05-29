import 'package:flutter/foundation.dart';
import '../services/contributor/contributor_service.dart';

class ContributorProvider extends ChangeNotifier {
  final ContributorService _service;

  ContributorProvider({required ContributorService service}) : _service = service;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic> _songs = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get songs => _songs;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getContributorDashboard();
      _stats = data['stats'] as Map<String, dynamic>?;
      _songs = (data['songs'] as List?) ?? [];
    } catch (e) {
      _error = 'Failed to load contributor dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePayout({
    required String method,
    String? paypalEmail,
    Map<String, dynamic>? bankAccount,
    String? stripeAccountId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updatePayoutInfo(
        method: method,
        paypalEmail: paypalEmail,
        bankAccount: bankAccount,
        stripeAccountId: stripeAccountId,
      );
      if (_stats != null) {
        // Refresh local dashboard representation if loaded
        await fetchDashboard();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update payout: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptContributorTerms(String version) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.acceptTerms(version);
      if (_stats != null) {
        _stats!['acceptedTerms'] = data['acceptedTerms'] ?? true;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to accept terms: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
