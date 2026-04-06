import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/config/api_config.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/models/genre_model.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/data/services/home_service.dart';
import 'package:lugmatic_flutter/data/services/music_service.dart';
import 'package:lugmatic_flutter/features/music/presentation/pages/genre_music_page.dart';
import 'package:lugmatic_flutter/features/music/presentation/pages/trending_songs_page.dart';
import '../../../home/presentation/widgets/music_card.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../../core/constants/app_colors.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  late HomeService _homeService;
  late MusicService _musicService;

  bool _isLoading = true;
  bool _isSearching = false;

  List<MusicModel> _trendingSongs = [];
  List<MusicModel> _newReleases = [];
  List<ArtistModel> _featuredArtists = [];
  List<GenreModel> _realGenres = [];
  List<MusicModel> _searchResults = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _homeService = HomeService(apiClient: apiClient);
    _musicService = MusicService(apiClient: apiClient);
    _loadDiscoveryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDiscoveryData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final trending = await _homeService.getTrendingSongs();
      final newReleases = await _homeService.getNewReleases();
      final artists = await _homeService.getFeaturedArtists();
      final genres = await _musicService.getGenres();

      if (mounted) {
        setState(() {
          _trendingSongs = trending;
          _newReleases = newReleases;
          _featuredArtists = artists;
          _realGenres = genres;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await _musicService.searchSongs(query.trim());
        if (mounted) setState(() { _searchResults = results; _isSearching = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = _searchController.text.trim().isNotEmpty;

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
                        const SizedBox(height: 16),
                        if (showSearch) ...[
                          _buildSearchResults(),
                        ] else ...[
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
                        ],
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
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
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
        decoration: InputDecoration(
          hintText: 'Search songs, artists, albums...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchResults = []; _isSearching = false; });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) {
          setState(() {}); // rebuild to show/hide clear button
          _onSearchChanged(v);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No results found', style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._searchResults.map((song) => _buildSongListItem(song, queue: _searchResults)).toList(),
        ],
      ),
    );
  }

  Widget _buildGenresGrid() {
    if (_realGenres.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Genre',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _realGenres.map((genre) => _buildGenreChip(genre)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(GenreModel genre) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GenreMusicPage(genre: genre)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            genre.name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
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
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: () {
                if (title == 'Trending Now') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrendingSongsPage()));
                }
              },
              child: Text(
                action,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingSongs() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trendingSongs.length,
        itemBuilder: (context, index) {
          final song = _trendingSongs[index];
          return MusicCard(
            music: song,
            showGlow: true,
            onTap: () => _openMusicPlayer(song, queue: _trendingSongs),
            onPlay: () => _openMusicPlayer(song, queue: _trendingSongs),
          );
        },
      ),
    );
  }

  Widget _buildNewReleases() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _newReleases.map((song) => _buildSongListItem(song, queue: _newReleases)).toList(),
      ),
    );
  }

  Widget _buildFeaturedArtists() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredArtists.length,
        itemBuilder: (context, index) {
          final artist = _featuredArtists[index];
          return _buildArtistCard(artist);
        },
      ),
    );
  }

  Widget _buildSongListItem(MusicModel song, {List<MusicModel>? queue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.imageUrl.isNotEmpty
                ? Image.network(
                    song.imageUrl,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderArt(),
                  )
                : _placeholderArt(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${song.artist} • ${song.genre}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openMusicPlayer(song, queue: queue),
            icon: const Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipOval(
            child: artist.imageUrl.isNotEmpty
                ? Image.network(
                    ApiConfig.resolveUrl(artist.imageUrl),
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderAvatar(),
                  )
                : _placeholderAvatar(),
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (artist.isVerified)
            const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
        ],
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 80, height: 80,
      color: Colors.white10,
      child: const Icon(Icons.person, color: Colors.white38, size: 36),
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
}
