import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/config/api_config.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/core/constants/app_colors.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/services/home_service.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/custom_app_bar.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/playlist_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/playlist_list_item.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/custom_bottom_nav.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/music_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/artist_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/podcast_card.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/ui/widgets/player_screen.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/notifications_page.dart';
import 'package:lugmatic_flutter/shared/widgets/demand_artist_dialog.dart';
import 'package:lugmatic_flutter/data/services/notification_service.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/create_playlist_screen.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/explore_hub_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/home_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/radio_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/library_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/browse_page.dart';
import 'package:lugmatic_flutter/features/music/presentation/pages/music_hub_page.dart';
import 'package:lugmatic_flutter/features/podcast/presentation/pages/podcast_hub_page.dart';
import 'package:lugmatic_flutter/features/gift/presentation/pages/gift_hub_page.dart';
import 'package:lugmatic_flutter/features/playlist/presentation/pages/playlist_detail_page.dart';
import 'package:lugmatic_flutter/data/models/playlist_model.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/pages/tiktok_live_page.dart';
import 'package:lugmatic_flutter/features/video/presentation/pages/videos_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/artist_detail_page.dart';
import 'package:lugmatic_flutter/features/song/presentation/pages/song_detail_page.dart';
import 'package:lugmatic_flutter/data/models/live_clash_model.dart';
import 'package:lugmatic_flutter/data/services/live_stream_service.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/pages/clash_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  late HomeService _homeService;
  bool _isLoading = true;

  List<MusicModel> _trendingSongs = [];
  List<ArtistModel> _featuredArtists = [];
  List<PodcastModel> _featuredPodcasts = [];
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _playlists = [];
  List<LiveClashModel> _recentClashes = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeService = HomeService(
        apiClient: context.read<ApiClient>(),
      );
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    
    // Load unread notifications separately (not part of the main UI blocks)
    _loadNotifications();

    // Start loading each section independently for "Granular Loading"
    setState(() => _isLoading = false); // We stop the global full-screen spinner earlier

    // Trending Songs
    _homeService.getTrendingSongs().then((songs) {
      if (mounted) setState(() => _trendingSongs = songs);
    });

    // Featured Artists
    _homeService.getFeaturedArtists().then((artists) {
      if (mounted) setState(() => _featuredArtists = artists);
    });

    // Featured Podcasts
    _homeService.getFeaturedPodcasts().then((podcasts) {
      if (mounted) setState(() => _featuredPodcasts = podcasts);
    });

    // Genres
    _loadGenres(apiClient).then((genres) {
      if (mounted) setState(() => _genres = genres);
    });

    // Playlists
    _loadPlaylists(apiClient).then((playlists) {
      if (mounted) setState(() => _playlists = playlists);
    });

    // Recent Clashes
    final liveStreamService = LiveStreamService(apiClient: apiClient);
    liveStreamService.getRecentClashes().then((clashes) {
      if (mounted) setState(() => _recentClashes = clashes);
    });
  }

  Future<List<Map<String, dynamic>>> _loadGenres(ApiClient apiClient) async {
    try {
      final res = await apiClient.dio.get(ApiConfig.genres);
      final body = res.data;
      final items = body['data'] ?? body['genres'] ?? [];
      return List<Map<String, dynamic>>.from(items as List);
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> _loadPlaylists(ApiClient apiClient) async {
    try {
      // Try mobile playlists first, then fall back to general playlist API
      final res = await apiClient.dio.get('/mobile/playlists');
      final body = res.data;
      final items = body['data'] ?? body['playlists'] ?? [];
      return List<Map<String, dynamic>>.from(items as List);
    } catch (_) {
      try {
        final res = await apiClient.dio.get('/playlist/my/list');
        final body = res.data;
        final items = body['data'] ?? body['playlists'] ?? [];
        return List<Map<String, dynamic>>.from(items as List);
      } catch (_) { return []; }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final service = context.read<NotificationService>();
      final items = await service.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotifications = items.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }


  Widget _buildHomePage() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 28),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 36),

            // Live Now section
            _buildSectionHeader('Live Now', 'View All'),
            const SizedBox(height: 18),
            _buildLiveSection(),
            const SizedBox(height: 36),

            // Recent Clashes section
            if (_recentClashes.isNotEmpty) ...[
              _buildSectionHeader('Recent Clashes', 'Review'),
              const SizedBox(height: 18),
              _buildClashHistorySection(),
              const SizedBox(height: 36),
            ],

            // Trending Songs
            _buildSectionHeader('Trending Now', 'See All'),
            const SizedBox(height: 18),
            _buildTrendingSongs(),
            const SizedBox(height: 36),

            // Featured Artists
            if (_featuredArtists.isNotEmpty) ...[  
              _buildSectionHeader('Featured Artists', 'View All'),
              const SizedBox(height: 18),
              _buildFeaturedArtists(),
              const SizedBox(height: 36),
            ],

            // Genres Section
            if (_genres.isNotEmpty) ...[  
              _buildSectionHeader('Browse by Genre', ''),
              const SizedBox(height: 18),
              _buildGenresSection(),
              const SizedBox(height: 36),
            ],

            // Made for You Section
            _buildSectionHeader('Made for You', ''),
            const SizedBox(height: 18),
            _buildMadeForYou(),
            const SizedBox(height: 36),

            // Popular Podcasts
            if (_featuredPodcasts.isNotEmpty) ...[  
              _buildSectionHeader('Podcasts', 'Browse'),
              const SizedBox(height: 18),
              _buildPopularPodcasts(),
              const SizedBox(height: 36),
            ],

            // Demand Artist
            _buildDemandArtistBanner(),
            const SizedBox(height: 36),

            // Recently Played
            _buildSectionHeader('Recently Played', ''),
            const SizedBox(height: 18),
            _buildRecentlyPlayed(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0
          ? CustomAppBar(
              title: 'Lugmatic',
              unreadCount: _unreadNotifications,
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                ).then((_) => _loadNotifications());
              },
              onProfileTap: () {
                // Navigate to profile page
                print('Profile tapped');
              },
              onStoreTap: () {
                Navigator.pushNamed(context, '/store');
              },
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const ExploreHubPage(),
          const TikTokLivePage(),
          const VideosPage(),
          const LibraryPage(),
        ],
      ),
      // floatingActionButton and floatingActionButtonLocation removed because MiniPlayer overlays bottom bar now
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onPlayTap: () {
          if (_trendingSongs.isNotEmpty) {
            _openMusicPlayer(_trendingSongs[0], queue: _trendingSongs);
          }
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.15),
            Colors.black.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDim],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover New Hits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Welcome to Lugmatic Music',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildWelcomeAction(
                  icon: Icons.add_rounded,
                  label: 'Add New',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlaylistScreen())),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              _buildWelcomeActionSmall(
                icon: Icons.live_tv_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TikTokLivePage())),
              ),
              const SizedBox(width: 12),
              _buildWelcomeActionSmall(
                icon: Icons.person_add_alt_1_rounded,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DemandArtistDialog(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAction({required IconData icon, required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.white : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeActionSmall({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionItem(
            icon: Icons.music_note,
            title: 'Music',
            subtitle: 'Stream',
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicHubPage())),
          ),
          const SizedBox(width: 12),
          _buildQuickActionItem(
            icon: Icons.mic,
            title: 'Podcasts',
            subtitle: 'Listen',
            color: AppColors.secondary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PodcastHubPage())),
          ),
          const SizedBox(width: 12),
          _buildQuickActionItem(
            icon: Icons.card_giftcard,
            title: 'Gifts',
            subtitle: 'Support',
            color: const Color(0xFFFFD700),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftHubPage())),
          ),
          const SizedBox(width: 12),
          _buildQuickActionItem(
            icon: Icons.auto_awesome,
            title: 'AI Mixer',
            subtitle: 'Remix',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/mixer'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 110,
      child: _buildQuickActionCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: color,
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.border,
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        if (action.isNotEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
            onTap: () => print('$action tapped'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
              action,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendingSongs() {
    if (_trendingSongs.isEmpty) {
      return _buildEmptyPlaceholder(
        icon: Icons.music_note_outlined,
        title: 'No trending songs yet',
        subtitle: 'Check back soon for trending hits',
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trendingSongs.length,
        itemBuilder: (context, index) {
          final song = _trendingSongs[index];
          return MusicCard(
            music: song,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SongDetailPage(songId: song.id, initialData: song)),
            ),
            onPlay: () => _openMusicPlayer(song, queue: _trendingSongs),
            onLike: () => print('Like ${song.title}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlaceholder({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.2), size: 48),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLiveSection() {
    // No real live data — show a compelling placeholder
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withOpacity(0.15),
            const Color(0xFFDC2626).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: const Icon(Icons.live_tv_rounded, color: Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No live streams right now',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Artists go live here — follow them to get notified',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TikTokLivePage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: const Text('Browse', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresSection() {
    final genreColors = [
      [AppColors.primary, const Color(0xFF059669)],
      [AppColors.secondary, const Color(0xFF7C3AED)],
      [AppColors.error, const Color(0xFFDC2626)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      [const Color(0xFFF97316), const Color(0xFFEA580C)],
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _genres.take(8).length,
      itemBuilder: (context, i) {
        final genre = _genres[i];
        final name = genre['name']?.toString() ?? '';
        final colors = genreColors[i % genreColors.length];
        return GestureDetector(
          onTap: () {
            // Navigate to browse page filtered by genre
            setState(() => _currentIndex = 1);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: AppColors.mutedForeground, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemandArtistBanner() {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => const DemandArtistDialog(),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary.withOpacity(0.2), const Color(0xFF7C3AED).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded, color: Color(0xFF8B5CF6), size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Missing an artist?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('Request them and we\'ll add them to Lugmatic.', style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF8B5CF6), size: 16),
          ],
        ),
      ),
    );
  }

  void _openMusicPlayer(MusicModel music, {List<MusicModel>? queue}) {
    context.read<AudioProvider>().playMusic(music, queue: queue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(music: music),
    );
  }

  Widget _buildFeaturedArtists() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredArtists.length,
        itemBuilder: (context, index) {
          final artist = _featuredArtists[index];
          return ArtistCard(
            artist: artist,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistDetailPage(artistId: artist.id, initialData: artist),
              ),
            ),
            onFollow: () => print('Follow ${artist.name}'),
            onGift: () => print('Gift ${artist.name}'),
          );
        },
      ),
    );
  }

  Widget _buildPopularPodcasts() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredPodcasts.length,
        itemBuilder: (context, index) {
          final podcast = _featuredPodcasts[index];
          return PodcastCard(
            podcast: podcast,
            onTap: () => _openPodcastPlayer(podcast),
            onPlay: () => _openPodcastPlayer(podcast),
            onLike: () => print('Like ${podcast.title}'),
          );
        },
      ),
    );
  }

  void _openPodcastPlayer(PodcastModel podcast) {
    // Convert podcast to music model for playback
    final musicModel = MusicModel(
      id: podcast.id,
      title: podcast.title,
      artist: podcast.host,
      album: podcast.seriesTitle,
      imageUrl: podcast.imageUrl,
      audioUrl: podcast.audioUrl,
      duration: podcast.duration,
      genre: podcast.category,
      releaseDate: podcast.publishDate,
    );
    _openMusicPlayer(musicModel);
  }

  void _openPlaylistDetail(PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailPage(playlist: playlist),
      ),
    );
  }


  Widget _buildMadeForYou() {
    if (_playlists.isEmpty) {
      return _buildEmptyPlaylistPrompt(
        icon: Icons.queue_music_rounded,
        title: 'Your playlists will appear here',
        subtitle: 'Create a playlist to get started',
        actionLabel: 'Create Playlist',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()),
        ),
      );
    }
    // Show first two playlists as featured cards
    final featured = _playlists.take(2).toList();
    final gradients = [
      [const Color(0xFF4CAF50), const Color(0xFF2196F3)],
      [const Color(0xFFFF9800), const Color(0xFFE91E63)],
    ];
    return Row(
      children: featured.asMap().entries.map((e) {
        final pl = e.value;
        final name = pl['name']?.toString() ?? pl['title']?.toString() ?? 'Playlist';
        final desc = pl['description']?.toString() ?? pl['subtitle']?.toString() ?? '';
        final gradient = gradients[e.key % gradients.length];
        final coverUrl = ApiConfig.resolveUrl(pl['coverImage']?.toString() ?? pl['imageUrl']?.toString() ?? '');
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openPlaylistFromMap(pl),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: coverUrl.isEmpty
                        ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)
                        : null,
                      image: coverUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                        : null,
                      boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (desc.isNotEmpty) Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
              if (e.key == 0) const SizedBox(width: 14),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentlyPlayed() {
    // Show remaining playlists (after the first 2 used in Made for You)
    final shown = _playlists.skip(2).take(5).toList();
    if (shown.isEmpty) {
      return _buildEmptyPlaylistPrompt(
        icon: Icons.history_rounded,
        title: 'No playlists yet',
        subtitle: 'Playlists you create will appear here',
        actionLabel: 'Browse Music',
        onAction: () => setState(() => _currentIndex = 1),
      );
    }
    return Column(
      children: shown.asMap().entries.map((e) {
        final pl = e.value;
        final name = pl['name']?.toString() ?? pl['title']?.toString() ?? 'Playlist';
        final desc = pl['description']?.toString() ?? pl['subtitle']?.toString() ?? '';
        final gradients = [
          [const Color(0xFFFF5722), const Color(0xFFFF9800)],
          [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
          [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
          [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
          [const Color(0xFFFF9800), const Color(0xFFFFEB3B)],
        ];
        final colors = gradients[e.key % gradients.length];
        return Column(
          children: [
            GestureDetector(
              onTap: () => _openPlaylistFromMap(pl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (desc.isNotEmpty) Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                  ],
                ),
              ),
            ),
            if (e.key < shown.length - 1) const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _openPlaylistFromMap(Map<String, dynamic> pl) {
    final id = pl['_id']?.toString() ?? pl['id']?.toString() ?? '';
    final name = pl['name']?.toString() ?? pl['title']?.toString() ?? 'Playlist';
    _openPlaylistDetail(PlaylistModel(
      id: id,
      title: name,
      subtitle: pl['description']?.toString() ?? '',
      imageUrl: ApiConfig.resolveUrl(pl['coverImage']?.toString() ?? pl['imageUrl']?.toString() ?? ''),
      type: 'playlist',
    ));
  }

  Widget _buildEmptyPlaylistPrompt({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.25), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(actionLabel, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTikTokLiveStreams() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredArtists.length,
        itemBuilder: (context, index) {
          final artist = _featuredArtists[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildLiveStreamCard(artist, index),
          );
        },
      ),
    );
  }

  Widget _buildLiveStreamCard(ArtistModel artist, int index) {
    final isLive = index < 2; // First two artists are "live"
    final viewerCount = isLive ? (1200 + index * 500) : 0;
    
    return GestureDetector(
      onTap: () {
        if (isLive) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TikTokLivePage(),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isLive ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.8),
                    Colors.blue.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(artist.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isLive) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Live indicator
            if (isLive)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Viewer count
            if (isLive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${viewerCount.toString()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Offline overlay
            if (!isLive)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildClashHistorySection() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentClashes.length,
        itemBuilder: (context, index) {
          final clash = _recentClashes[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClashDetailsPage(
                    clashId: clash.id,
                    initialData: clash,
                  ),
                ),
              );
            },
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  // Background Decoration
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CLASH',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'REVIEW',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildMiniArtist(clash.challenger.name, clash.challenger.image),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                            _buildMiniArtist(clash.opponent.name, clash.opponent.image),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Winner: ${clash.winnerId == clash.challenger.id ? clash.challenger.name : (clash.winnerId == clash.opponent.id ? clash.opponent.name : 'Draw')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniArtist(String name, String image) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: NetworkImage(ApiConfig.resolveUrl(image)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}