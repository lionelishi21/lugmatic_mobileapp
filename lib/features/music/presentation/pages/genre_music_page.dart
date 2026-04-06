import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/genre_model.dart';
import '../../../../data/services/music_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../home/presentation/widgets/music_card.dart';
import '../../../../core/config/api_config.dart';

class GenreMusicPage extends StatefulWidget {
  final GenreModel genre;

  const GenreMusicPage({Key? key, required this.genre}) : super(key: key);

  @override
  State<GenreMusicPage> createState() => _GenreMusicPageState();
}

class _GenreMusicPageState extends State<GenreMusicPage> {
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
      final newSongs = await _musicService.getSongsByGenre(
        widget.genre.id,
        page: _currentPage,
        limit: 20,
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
          SnackBar(content: Text('Error loading songs: $e')),
        );
      }
    }
  }

  Color _getGenreColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'rose':
        return const Color(0xFFF43F5E);
      case 'orange':
        return const Color(0xFFFB923C);
      case 'violet':
        return const Color(0xFF8B5CF6);
      case 'cyan':
        return const Color(0xFF22D3EE);
      case 'amber':
        return const Color(0xFFFBBF24);
      case 'emerald':
        return const Color(0xFF10B981);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'indigo':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
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
          _buildSongsGrid(),
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
    final genreColor = _getGenreColor(widget.genre.color);
    
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Text(
          widget.genre.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.genre.image != null && widget.genre.image!.isNotEmpty)
              Image.network(
                ApiConfig.resolveUrl(widget.genre.image!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackBackground(genreColor),
              )
            else
              _buildFallbackBackground(genreColor),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFallbackBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.2),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: Icon(
            Icons.music_note,
            size: 150,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSongsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = _songs[index];
            return MusicCard(
              music: song,
              showGlow: true,
              onTap: () => _openPlayer(song),
              onPlay: () => _openPlayer(song),
            );
          },
          childCount: _songs.length,
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
