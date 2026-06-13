import 'package:flutter/foundation.dart';
import '../models/artist/dashboard_models.dart';
import '../services/artist/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  DashboardProvider({required DashboardService service}) : _service = service;

  bool _isLoading = false;
  String? _error;
  ArtistDetails? _artistDetails;
  ArtistStats? _artistStats;
  ArtistEarnings? _artistEarnings;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ArtistDetails? get artistDetails => _artistDetails;
  ArtistStats? get artistStats => _artistStats;
  ArtistEarnings? get artistEarnings => _artistEarnings;

  Future<void> fetchDashboardData(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getArtistDetails(artistId),
        _service.getArtistStats(artistId),
        _service.getArtistEarnings(),
      ]);
      _artistDetails = results[0] as ArtistDetails;
      _artistStats = results[1] as ArtistStats;
      _artistEarnings = results[2] as ArtistEarnings;
    } catch (e) {
      _error = 'Failed to load dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _artistDetails = null;
    _artistStats = null;
    _artistEarnings = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestPayout(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.requestPayout(amount);
      return true;
    } catch (e) {
      _error = e.toString();
      // Try to parse dio error message
      if (e is num || e.toString().contains('DioException')) {
        // Simple extraction fallback
        _error = 'Failed to request payout. Minimum is \$50.00 or check your balance.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
