// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/custom_app_bar.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/playlist_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/playlist_list_item.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/custom_bottom_nav.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/music_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/artist_card.dart';
import 'package:lugmatic_flutter/features/home/presentation/widgets/podcast_card.dart';
import 'package:lugmatic_flutter/ui/widgets/music_player_widget.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/create_playlist_screen.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/live_artist_screen.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/browse_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/radio_page.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/library_page.dart';
import 'package:lugmatic_flutter/features/music/presentation/pages/music_hub_page.dart';
import 'package:lugmatic_flutter/features/podcast/presentation/pages/podcast_hub_page.dart';
import 'package:lugmatic_flutter/features/gift/presentation/pages/gift_hub_page.dart';
import 'package:lugmatic_flutter/features/playlist/presentation/pages/playlist_detail_page.dart';
import 'package:lugmatic_flutter/features/home/data/models/playlist_model.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/pages/tiktok_live_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();


  // Sample data - in a real app, this would come from your data layer
  final List<MusicModel> _trendingSongs = [
    MusicModel(
      id: '4',
      title: 'Under The Influence',
      artist: 'Chris Brown',
      album: 'Breezy',
      imageUrl: 'assets/images/onboarding_guy.png',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: const Duration(minutes: 3, seconds: 4),
      genre: 'R&B',
      releaseDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MusicModel(
      id: '1',
      title: 'Midnight Dreams',
      artist: 'Luna Nova',
      album: 'Cosmic Vibes',
      imageUrl: 'assets/images/music_background_1.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: const Duration(minutes: 3, seconds: 45),
      genre: 'Electronic',
      releaseDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MusicModel(
      id: '2',
      title: 'Ocean Waves',
      artist: 'Marine Sounds',
      album: 'Nature Therapy',
      imageUrl: 'assets/images/music_background_2.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: const Duration(minutes: 4, seconds: 12),
      genre: 'Ambient',
      releaseDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MusicModel(
      id: '3',
      title: 'City Lights',
      artist: 'Urban Beats',
      album: 'Metropolitan',
      imageUrl: 'assets/images/music_background_3.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: const Duration(minutes: 3, seconds: 28),
      genre: 'Hip-Hop',
      releaseDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<ArtistModel> _featuredArtists = [
    ArtistModel(
      id: '4',
      name: 'Chris Brown',
      imageUrl: 'assets/images/onboarding_guy.png',
      bio: 'Multi-platinum R&B and hip-hop artist, dancer, and actor',
      followers: 45000000,
      genres: ['R&B', 'Hip-Hop', 'Pop'],
      isVerified: true,
      location: 'Tappahannock, VA',
      totalSongs: 200,
      totalAlbums: 15,
      rating: 4.9,
    ),
    ArtistModel(
      id: '1',
      name: 'Luna Nova',
      imageUrl: 'assets/images/icon.png',
      bio: 'Electronic music producer creating cosmic soundscapes',
      followers: 125000,
      genres: ['Electronic', 'Ambient', 'Synthwave'],
      isVerified: true,
      location: 'Los Angeles, CA',
      totalSongs: 45,
      totalAlbums: 8,
      rating: 4.8,
    ),
    ArtistModel(
      id: '2',
      name: 'Marine Sounds',
      imageUrl: 'assets/images/icon.png',
      bio: 'Nature-inspired ambient music for relaxation',
      followers: 89000,
      genres: ['Ambient', 'Nature', 'Meditation'],
      isVerified: true,
      location: 'Portland, OR',
      totalSongs: 32,
      totalAlbums: 6,
      rating: 4.9,
    ),
    ArtistModel(
      id: '3',
      name: 'Urban Beats',
      imageUrl: 'assets/images/icon.png',
      bio: 'Hip-hop artist bringing fresh urban vibes',
      followers: 156000,
      genres: ['Hip-Hop', 'Rap', 'Urban'],
      isVerified: true,
      location: 'New York, NY',
      totalSongs: 67,
      totalAlbums: 12,
      rating: 4.7,
    ),
  ];

  final List<PodcastModel> _featuredPodcasts = [
    PodcastModel(
      id: '1',
      title: 'The Future of Music Technology',
      description: 'Exploring how AI and technology are reshaping the music industry',
      host: 'Tech Music Podcast',
      imageUrl: 'assets/images/placeholder_bg.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: const Duration(minutes: 45, seconds: 30),
      category: 'Technology',
      publishDate: DateTime.now().subtract(const Duration(days: 2)),
      episodeNumber: 15,
      totalEpisodes: 50,
      seriesId: 'tech-music',
      seriesTitle: 'Tech Music Podcast',
    ),
    PodcastModel(
      id: '2',
      title: 'Artist Stories: Behind the Music',
      description: 'Intimate conversations with rising artists about their creative process',
      host: 'Music Stories',
      imageUrl: 'assets/images/placeholder_bg.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      duration: const Duration(minutes: 38, seconds: 15),
      category: 'Interviews',
      publishDate: DateTime.now().subtract(const Duration(days: 1)),
      episodeNumber: 23,
      totalEpisodes: 75,
      seriesId: 'artist-stories',
      seriesTitle: 'Artist Stories',
    ),
  ];


  Widget _buildHomePage() {
    return SingleChildScrollView(
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
          
          // TikTok-Style Live Streams
          _buildSectionHeader('Live Now', 'View All'),
          const SizedBox(height: 18),
          _buildTikTokLiveStreams(),
          const SizedBox(height: 36),
          
          // Trending Songs
          _buildSectionHeader('Trending Now', 'See All'),
          const SizedBox(height: 18),
          _buildTrendingSongs(),
          const SizedBox(height: 36),
          
          // Featured Artists
          _buildSectionHeader('Featured Artists', 'View All'),
          const SizedBox(height: 18),
          _buildFeaturedArtists(),
          const SizedBox(height: 36),
          
          // Made for You Section
          _buildSectionHeader('Made for You', ''),
          const SizedBox(height: 18),
          _buildMadeForYou(),
          const SizedBox(height: 36),
          
          // Popular Podcasts
          _buildSectionHeader('Podcasts', 'Browse'),
          const SizedBox(height: 18),
          _buildPopularPodcasts(),
          const SizedBox(height: 36),
          
          // Recently Played
          _buildSectionHeader('Recently Played', ''),
          const SizedBox(height: 18),
          _buildRecentlyPlayed(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: _currentIndex == 0
          ? CustomAppBar(
              title: 'Lugmatic Music',
              onProfileTap: () {
                // Navigate to profile page
                print('Profile tapped');
              },
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const BrowsePage(),
          const RadioPage(),
          const LibraryPage(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onPlayTap: () {
          if (_trendingSongs.isNotEmpty) {
            _openMusicPlayer(_trendingSongs[0]);
          }
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
            'Good Morning!',
            style: TextStyle(
              color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ready to discover new music?',
            style: TextStyle(
              color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePlaylistScreen(),
                      ),
                    );
                  },
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Create Playlist',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                    if (_featuredArtists.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveArtistScreen(artist: _featuredArtists[0]),
                        ),
                      );
                    }
                  },
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.music_note,
            title: 'Music',
            subtitle: 'Stream & Discover',
            color: const Color(0xFF10B981),
            onTap: () {
              print('Music button tapped - navigating to MusicHubPage');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MusicHubPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.mic,
            title: 'Podcasts',
            subtitle: 'Listen & Learn',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              print('Podcasts button tapped - navigating to PodcastHubPage');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PodcastHubPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.card_giftcard,
            title: 'Gifts',
            subtitle: 'Support Artists',
            color: const Color(0xFFFFD700),
            onTap: () {
              print('Gifts button tapped - navigating to GiftHubPage');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GiftHubPage(),
                ),
              );
            },
          ),
        ),
      ],
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
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
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
                  color: Colors.white.withOpacity(0.6),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
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
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
              action,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF10B981),
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
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trendingSongs.length,
        itemBuilder: (context, index) {
          final song = _trendingSongs[index];
          return MusicCard(
            music: song,
            onTap: () => _openMusicPlayer(song),
            onPlay: () => _openMusicPlayer(song),
            onLike: () => print('Like ${song.title}'),
          );
        },
      ),
    );
  }

  void _openMusicPlayer(MusicModel music) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerWidget(music: music),
        fullscreenDialog: true,
      ),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveArtistScreen(artist: artist),
                ),
              );
            },
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
    return Row(
      children: [
        Expanded(
          child: PlaylistCard(
            title: 'Chill Mix',
            subtitle: 'Electronic',
            gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2196F3)],
            onTap: () => _openPlaylistDetail(
              PlaylistModel(
                id: 'chill_mix',
                title: 'Chill Mix',
                subtitle: 'Electronic',
                imageUrl: 'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Chill',
                type: 'playlist',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PlaylistCard(
            title: 'Energy Boost',
            subtitle: 'Upbeat',
            gradientColors: [const Color(0xFFFF9800), const Color(0xFFE91E63)],
            onTap: () => _openPlaylistDetail(
              PlaylistModel(
                id: 'energy_boost',
                title: 'Energy Boost',
                subtitle: 'Upbeat',
                imageUrl: 'https://via.placeholder.com/300x300/FF9800/FFFFFF?text=Energy',
                type: 'playlist',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyPlayed() {
    return Column(
      children: [
        PlaylistListItem(
          title: 'Top 100 Hits',
          artist: 'Lugmatic Music',
          gradientColors: [const Color(0xFFFF5722), const Color(0xFFFF9800)],
          onTap: () => _openPlaylistDetail(
            PlaylistModel(
              id: 'top_100_hits',
              title: 'Top 100 Hits',
              subtitle: 'Lugmatic Music',
              imageUrl: 'https://via.placeholder.com/300x300/FF5722/FFFFFF?text=Top100',
              type: 'playlist',
            ),
          ),
          onMoreTap: () => print('More options tapped'),
        ),
        const SizedBox(height: 16),
        PlaylistListItem(
          title: 'Acoustic Mornings',
          artist: 'Lugmatic Music',
          gradientColors: [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
          onTap: () => _openPlaylistDetail(
            PlaylistModel(
              id: 'acoustic_mornings',
              title: 'Acoustic Mornings',
              subtitle: 'Lugmatic Music',
              imageUrl: 'https://via.placeholder.com/300x300/2196F3/FFFFFF?text=Acoustic',
              type: 'playlist',
            ),
          ),
          onMoreTap: () => print('More options tapped'),
        ),
        const SizedBox(height: 16),
        PlaylistListItem(
          title: 'Road Trip Jams',
          artist: 'Lugmatic Music',
          gradientColors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
          onTap: () => _openPlaylistDetail(
            PlaylistModel(
              id: 'road_trip_jams',
              title: 'Road Trip Jams',
              subtitle: 'Lugmatic Music',
              imageUrl: 'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=RoadTrip',
              type: 'playlist',
            ),
          ),
          onMoreTap: () => print('More options tapped'),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
              ),
            ],
          ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_trendingSongs.isNotEmpty) {
              _openMusicPlayer(_trendingSongs[0]);
            }
          },
          borderRadius: BorderRadius.circular(32),
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
            color: Colors.white,
              size: 36,
            ),
          ),
        ),
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
              builder: (context) => TikTokLivePage(artist: artist),
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
}