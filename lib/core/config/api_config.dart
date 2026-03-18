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

  /// Storage base URL for resolving relative media paths (/uploads/...)
  static const String storageBaseUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: 'https://api.lugmaticmusic.com',
  );

  /// Resolve a potentially-relative media path to a full URL.
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$storageBaseUrl$path';
  }

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
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Song endpoints ──────────────────────────────────────────────
  static const String songs = '/song/list';
  static const String songDetails = '/song/details'; // + /:id

  // ── Artist endpoints ────────────────────────────────────────────
  static const String artists = '/artist/list';
  static const String mobileArtists = '/mobile/artists';
  static const String artistDetails = '/artist/details'; // + /:id
  static const String artistSongs = '/artist'; // + /:id/songs
  static const String artistAlbums = '/artist'; // + /:id/albums

  static const String gifts = '/gift';
  static const String sendGift = '/gift/send';
  static const String purchaseCoins = '/gift/purchase-coins';
  static const String createPaymentIntent = '/gift/create-payment-intent';
  static const String verifyPurchase = '/gift/verify-purchase';
  static const String coinBalance = '/gift/balance';

  // ── Album endpoints ─────────────────────────────────────────────
  static const String albums = '/album/list';
  static const String albumDetails = '/album/details'; // + /:id

  // ── Playlist endpoints ──────────────────────────────────────────
  static const String playlists = '/playlist';

  // ── Genre endpoints ────────────────────────────────────────────
  static const String genres = '/genre/list';
  static const String genreContent = '/genre/content'; // + /:id

  // ── Podcast endpoints ───────────────────────────────────────────
  static const String podcasts = '/podcast/list';
  static const String podcastDetails = '/podcast/details'; // + /:id

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

  // ── Clash endpoints ─────────────────────────────────────────────
  static const String clash = '/clash';
  static const String clashInvite = '/clash/invite';
  static const String clashAccept = '/clash/accept'; // + /:id
  static const String clashReject = '/clash/reject'; // + /:id
  static const String clashDetails = '/clash'; // + /:id
  static const String clashRankings = '/clash/rankings';

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
  static const String mobilePlaylists = '/playlist/my/list';
  static const String mobileSearch = '/mobile/search';
  static const String mobileFavorites = '/mobile/favorites';
  static const String recentlyPlayed = '/user/recently-played/list';
}
