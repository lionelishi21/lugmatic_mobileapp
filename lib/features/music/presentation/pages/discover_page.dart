import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/ui/widgets/player_screen.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/services/home_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  late HomeService _homeService;
  bool _isLoading = true;

  List<MusicModel> _trendingSongs = [];
  List<MusicModel> _newReleases = [];
  List<ArtistModel> _featuredArtists = [];

  final List<String> _genres = [
    'Pop', 'Rock', 'Hip-Hop', 'Electronic', 'Jazz', 'Classical',
    'Country', 'R&B', 'Reggae', 'Blues', 'Folk', 'Alternative'
  ];

  @override
  void initState() {
    super.initState();
    _homeService = HomeService(apiClient: context.read<ApiClient>());
    _loadDiscoveryData();
  }

  Future<void> _loadDiscoveryData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _homeService.getTrendingSongs(),
        _homeService.getNewReleases(),
        _homeService.getFeaturedArtists(),
      ]);

      if (mounted) {
        setState(() {
          _trendingSongs = results[0] as List<MusicModel>;
          _newReleases = results[1] as List<MusicModel>;
          _featuredArtists = results[2] as List<ArtistModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: RefreshIndicator(
        onRefresh: _loadDiscoveryData,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1F2937),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: _isLoading 
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildGenresGrid(),
                      const SizedBox(height: 32),
                      if (_trendingSongs.isNotEmpty) ...[
                        _buildSectionHeader('Trending Now', 'See All'),
                        const SizedBox(height: 16),
                        _buildTrendingSongs(),
                        const SizedBox(height: 32),
                      ],
                      if (_newReleases.isNotEmpty) ...[
                        _buildSectionHeader('New Releases', 'View All'),
                        const SizedBox(height: 16),
                        _buildNewReleases(),
                        const SizedBox(height: 32),
                      ],
                      if (_featuredArtists.isNotEmpty) ...[
                        _buildSectionHeader('Featured Artists', 'Browse'),
                        const SizedBox(height: 16),
                        _buildFeaturedArtists(),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionHeader('Recommended for You', ''),
                      const SizedBox(height: 16),
                      _buildRecommendedSongs(),
                      const SizedBox(height: 100),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Discover Music',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilterDialog(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search songs, artists, albums...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Handle search query changes
        },
      ),
    );
  }

  Widget _buildGenresGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Genre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) => _buildGenreChip(genre)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: () => print('$action tapped'),
              child: Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingSongs() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trendingSongs.length,
        itemBuilder: (context, index) {
          final song = _trendingSongs[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildSongCard(song),
          );
        },
      ),
    );
  }

  Widget _buildNewReleases() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _newReleases.map((song) => _buildSongListItem(song)).toList(),
      ),
    );
  }

  Widget _buildFeaturedArtists() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredArtists.length,
        itemBuilder: (context, index) {
          final artist = _featuredArtists[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: _buildArtistCard(artist),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedSongs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _trendingSongs.take(3).map((song) => _buildSongListItem(song)).toList(),
      ),
    );
  }

  Widget _buildSongCard(MusicModel song) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMusicPlayer(song),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(song.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.green.withOpacity(0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      song.genre,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongListItem(MusicModel song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(song.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (song.isArtistVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${song.genre} • ${_formatDuration(song.duration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openMusicPlayer(song),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print('Artist ${artist.name} tapped'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(artist.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (artist.isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  artist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist.genres.isNotEmpty ? artist.genres.first : 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(artist.followers)} followers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMusicPlayer(MusicModel music) {
    context.read<AudioProvider>().playMusic(music);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(music: music),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Filter Music',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your preferences',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            // Add filter options here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
