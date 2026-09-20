import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';

/// Single source of truth for "is this item favorited," keyed by
/// "type:id" (song/artist/album/playlist — whatever the backend's
/// /mobile/favorites/:type/:id endpoint supports). Every screen that shows
/// or toggles a like/favorite state should read and write through this
/// provider instead of keeping its own local bool, so liking something in
/// one place is reflected everywhere else that shows the same item.
class FavoriteProvider extends ChangeNotifier {
  final FavoritesService _service;
  FavoriteProvider({required FavoritesService service}) : _service = service;

  final Map<String, bool> _state = {};

  String _key(String type, String id) => '$type:$id';

  bool isFavorited(String type, String id) => _state[_key(type, id)] ?? false;

  /// Backfills the initial state for an item (e.g. from a list/detail API
  /// response's own `isLiked` field) without clobbering a value already
  /// tracked this session from a toggle made elsewhere.
  void seed(String type, String id, bool value) {
    final key = _key(type, id);
    if (!_state.containsKey(key)) {
      _state[key] = value;
    }
  }

  Future<void> toggle(String type, String id) async {
    final key = _key(type, id);
    final previous = _state[key] ?? false;
    final next = !previous;
    _state[key] = next;
    notifyListeners();
    try {
      await _service.setFavorite(type: type, id: id, favorited: next);
    } catch (e) {
      _state[key] = previous;
      notifyListeners();
      rethrow;
    }
  }
}
