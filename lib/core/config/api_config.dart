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
  static const String verifyEmail = '/auth/verify-email';

  // ── Song endpoints ──────────────────────────────────────────────
  static const String songs = '/song';
  static const String songDetails = '/song'; // + /:id

  // ── Artist endpoints ────────────────────────────────────────────
  static const String artists = '/artist';
  static const String artistDetails = '/artist'; // + /:id

  static const String gifts = '/gift';
  static const String sendGift = '/gift/send';
  static const String purchaseCoins = '/gift/purchase-coins';
  static const String createPaymentIntent = '/gift/create-payment-intent';
  static const String verifyPurchase = '/gift/verify-purchase';
  static const String coinBalance = '/gift/balance';

  // ── Album endpoints ─────────────────────────────────────────────
  static const String albums = '/album';
  static const String albumDetails = '/album'; // + /:id

  // ── Genre endpoints ────────────────────────────────────────────
  static const String genres = '/genre';

  // ── Playlist endpoints ──────────────────────────────────────────
  static const String playlists = '/playlist';

  // ── Podcast endpoints ───────────────────────────────────────────
  static const String podcasts = '/podcast';
  static const String podcastDetails = '/podcast'; // + /:id

  // ── Comment endpoints ───────────────────────────────────────────
  static const String comments = '/comment';
  static const String commentLike = '/comment'; // + /:id/like

  // ── Notification endpoints ──────────────────────────────────────
  static const String notifications = '/notification';
  static const String markRead = '/notification/read-all';

  // ── Artist Request endpoints ────────────────────────────────────
  static const String artistRequest = '/artist-request';
  static const String myArtistRequests = '/artist-request/my';

  // ── Search endpoints ────────────────────────────────────────────
  static const String search = '/search/global';

  // ── Live Stream endpoints ─────────────────────────────────────
  static const String liveStreams = '/live-stream';
  static const String liveStreamDetails = '/live-stream'; // + /:id
  static const String liveStreamToken = '/live-stream'; // + /:id/token

  // ── Video endpoints ─────────────────────────────────────────────
  static const String videos = '/video/list';
  static const String videoFeed = '/video/feed';
  static const String videoDetails = '/video/details'; // + /:id
  static const String songVideos = '/video/song'; // + /:id
  static const String videoView = '/video/view'; // + /:id

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
