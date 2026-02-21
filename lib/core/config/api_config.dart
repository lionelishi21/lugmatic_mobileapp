/// API configuration for the Lugmatic backend.
///
/// In production, these values should come from environment config
/// (e.g. flutter_dotenv or --dart-define).
class ApiConfig {
  ApiConfig._();

  /// Base URL for the Lugmatic API.
  /// Override with --dart-define=API_BASE_URL=https://api.lugmaticmusic.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.lugmaticmusic.com/api',
  );

  /// Connection timeout in milliseconds
  static const int connectTimeout = 15000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 15000;

  // ── Auth endpoints ──────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── Song endpoints ──────────────────────────────────────────────
  static const String songs = '/song';
  static const String songDetails = '/song'; // + /:id

  // ── Artist endpoints ────────────────────────────────────────────
  static const String artists = '/artist';
  static const String artistDetails = '/artist'; // + /:id

  // ── Gift endpoints ──────────────────────────────────────────────
  static const String gifts = '/gift';
  static const String sendGift = '/gift/send';
  static const String purchaseCoins = '/gift/purchase-coins';

  // ── Album endpoints ─────────────────────────────────────────────
  static const String albums = '/album';
  static const String albumDetails = '/album'; // + /:id

  // ── Genre endpoints ────────────────────────────────────────────
  static const String genres = '/genre';

  // ── Playlist endpoints ──────────────────────────────────────────
  static const String playlists = '/playlist';

  // ── Podcast endpoints ───────────────────────────────────────────
  static const String podcasts = '/podcast';

  // ── Search endpoints ────────────────────────────────────────────
  static const String search = '/search/global';

  // ── Live Stream endpoints ─────────────────────────────────────
  static const String liveStreams = '/live-stream';
  static const String liveStreamDetails = '/live-stream'; // + /:id
  static const String liveStreamToken = '/live-stream'; // + /:id/token

  // ── LiveKit ────────────────────────────────────────────────────
  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'wss://lugmaticmusic-m52lge19.livekit.cloud',
  );

  // ── Socket.io URL ───────────────────────────────────────────────
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://api.lugmaticmusic.com',
  );

  // ── Mobile-specific endpoints ───────────────────────────────────
  static const String mobilePlaylists = '/mobile/playlists';
  static const String mobileSearch = '/mobile/search';
  static const String mobileFavorites = '/mobile/favorites';
  static const String mobileArtists = '/mobile/artists';
}
