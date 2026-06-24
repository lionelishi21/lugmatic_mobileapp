import 'package:flutter/foundation.dart';

/// Tier drives which pop animation plays — mirrors the web app's
/// low/mid/high gift-pop system so the feel is consistent across platforms.
enum GiftPopTier { low, mid, high }

GiftPopTier resolveGiftPopTier(double coinCost) {
  if (coinCost >= 500) return GiftPopTier.high;
  if (coinCost >= 100) return GiftPopTier.mid;
  return GiftPopTier.low;
}

class GiftPopEvent {
  final String? username;
  final String giftName;
  final String? giftImageUrl;
  final double coinCost;
  final GiftPopTier tier;

  GiftPopEvent({
    this.username,
    required this.giftName,
    this.giftImageUrl,
    required this.coinCost,
  }) : tier = resolveGiftPopTier(coinCost);
}

/// Global singleton — fire from anywhere (socket handlers, gift-send success
/// callbacks) without needing a BuildContext. The overlay widget listens to
/// this directly via AnimatedBuilder since ChangeNotifier is a Listenable.
class GiftPopController extends ChangeNotifier {
  GiftPopController._();
  static final GiftPopController instance = GiftPopController._();

  GiftPopEvent? _event;
  int _seq = 0;

  GiftPopEvent? get event => _event;
  int get seq => _seq;

  void fire(GiftPopEvent event) {
    _event = event;
    _seq++;
    notifyListeners();
  }

  /// Called by the visual widget once its animation finishes.
  void clear() {
    if (_event == null) return;
    _event = null;
    notifyListeners();
  }
}
