import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/services/music_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../ui/widgets/player_screen.dart';

class TrendingSongsPage extends StatefulWidget {
  const TrendingSongsPage({Key? key}) : super(key: key);

  @override
  State<TrendingSongsPage> createState() => _TrendingSongsPageState();
}

class _TrendingSongsPageState extends State<TrendingSongsPage> {
  late MusicService _musicService;
  List<MusicModel> _songs = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _musicService = MusicService(apiClient: context.read<ApiClient>());
    _loadSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadSongs();
      }
    }
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final newSongs = await _musicService.getSongs(
        page: _currentPage,
        limit: 20,
        sort: '-playCount', // Fetch trending songs
      );

      if (mounted) {
        setState(() {
          _songs.addAll(newSongs);
          _isLoading = false;
          _currentPage++;
          if (newSongs.length < 20) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trending songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          _buildSongsList(),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Trending Now',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];
          return _buildSongListItem(song, index + 1);
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildSongListItem(MusicModel song, int rank) {
    return InkWell(
      onTap: () => _openPlayer(song),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? AppColors.primary : Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(width: 56, height: 56, color: Colors.grey[900]),
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
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white.withOpacity(0.5),
              ),
              onPressed: () {
                // Show options menu
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(MusicModel music) {
    context.read<AudioProvider>().playMusic(music, queue: _songs);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(music: music),
    );
  }
}
