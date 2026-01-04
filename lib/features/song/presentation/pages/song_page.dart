import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/music_model.dart';
import '../../../../core/theme/neumorphic_theme.dart';

class SongPage extends StatefulWidget {
  final MusicModel song;
  final List<MusicModel>? similarSongs;

  const SongPage({
    Key? key,
    required this.song,
    this.similarSongs,
  }) : super(key: key);

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isFavorite = false;
  bool _showLyrics = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  late AnimationController _rotationController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      setState(() => _isLoading = true);
      
      // Set up listeners
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });
          
          if (_isPlaying) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        }
      });

      // Load the audio
      await _audioPlayer.setUrl(widget.song.audioUrl);
      setState(() => _isLoading = false);
      
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _seek(double value) {
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  void _skipForward() {
    final newPosition = _position + const Duration(seconds: 15);
    _audioPlayer.seek(newPosition < _duration ? newPosition : _duration);
  }

  void _skipBackward() {
    final newPosition = _position - const Duration(seconds: 15);
    _audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
        backgroundColor: NeumorphicTheme.primaryAccent,
      ),
    );
  }

  void _shareSong() {
    Share.share(
      'Check out "${widget.song.title}" by ${widget.song.artist} on Lugmatic Music!',
      subject: widget.song.title,
    );
  }

  void _showAddToPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: NeumorphicTheme.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeumorphicTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add to Playlist',
              style: TextStyle(
                color: NeumorphicTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: NeumorphicTheme.gradientNeumorphicDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: const Text(
                'Create New Playlist',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create playlist feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: NeumorphicTheme.flatNeumorphicDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite, color: NeumorphicTheme.primaryAccent),
              ),
              title: const Text(
                'Favorites',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NeumorphicTheme.backgroundColor,
            NeumorphicTheme.surfaceColor,
            NeumorphicTheme.backgroundColor,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAlbumArt(),
                      const SizedBox(height: 32),
                      _buildSongInfo(),
                      const SizedBox(height: 28),
                      _buildProgressBar(),
                      const SizedBox(height: 32),
                      _buildPlaybackControls(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                      _buildSongDetails(),
                      const SizedBox(height: 24),
                      _buildLyricsSection(),
                      if (widget.similarSongs != null && widget.similarSongs!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSimilarSongs(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: NeumorphicButton(
          width: 40,
          height: 40,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: NeumorphicTheme.textPrimary,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: NeumorphicButton(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              // Show more options
              _showMoreOptions();
            },
            child: const Icon(
              Icons.more_vert,
              size: 24,
              color: NeumorphicTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumArt() {
    return Hero(
      tag: 'song_${widget.song.id}',
      child: RotationTransition(
        turns: _rotationController,
        child: NeumorphicContainer(
          width: 300,
          height: 300,
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(150),
          color: NeumorphicTheme.surfaceColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(140),
            child: widget.song.imageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: widget.song.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholderArt(),
                    errorWidget: (context, url, error) => _buildPlaceholderArt(),
                  )
                : Image.asset(
                    widget.song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderArt();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: NeumorphicTheme.cardColor,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 100,
          color: NeumorphicTheme.primaryAccent.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          widget.song.title,
          style: const TextStyle(
            color: NeumorphicTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Text(
          widget.song.artist,
          style: const TextStyle(
            color: NeumorphicTheme.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          widget.song.album,
          style: TextStyle(
            color: NeumorphicTheme.textTertiary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        NeumorphicContainer(
          isConcave: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          borderRadius: BorderRadius.circular(20),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: NeumorphicTheme.primaryAccent,
              inactiveTrackColor: NeumorphicTheme.backgroundColor,
              thumbColor: NeumorphicTheme.primaryAccent,
              overlayColor: NeumorphicTheme.primaryAccent.withOpacity(0.3),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 1.0,
              onChanged: _seek,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                  color: NeumorphicTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  color: NeumorphicTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeumorphicButton(
          width: 56,
          height: 56,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            // Implement shuffle
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shuffle feature coming soon!')),
            );
          },
          child: const Icon(
            Icons.shuffle,
            color: NeumorphicTheme.textSecondary,
            size: 24,
          ),
        ),
        const SizedBox(width: 20),
        NeumorphicButton(
          width: 60,
          height: 60,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          onPressed: _skipBackward,
          child: const Icon(
            Icons.replay_10,
            color: NeumorphicTheme.textPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: 24),
        _isLoading
            ? NeumorphicContainer(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(24),
                color: NeumorphicTheme.surfaceColor,
                child: const CircularProgressIndicator(
                  color: NeumorphicTheme.primaryAccent,
                  strokeWidth: 3,
                ),
              )
            : NeumorphicButton(
                width: 80,
                height: 80,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(24),
                isGradient: true,
                gradientColors: const [
                  NeumorphicTheme.accentGradientStart,
                  NeumorphicTheme.accentGradientEnd,
                ],
                onPressed: _playPause,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
        const SizedBox(width: 24),
        NeumorphicButton(
          width: 60,
          height: 60,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          onPressed: _skipForward,
          child: const Icon(
            Icons.forward_10,
            color: NeumorphicTheme.textPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        NeumorphicButton(
          width: 56,
          height: 56,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            // Implement repeat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Repeat feature coming soon!')),
            );
          },
          child: const Icon(
            Icons.repeat,
            color: NeumorphicTheme.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          label: 'Like',
          onPressed: _toggleFavorite,
          isActive: _isFavorite,
        ),
        _buildActionButton(
          icon: Icons.playlist_add,
          label: 'Add to',
          onPressed: _showAddToPlaylistDialog,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: _shareSong,
        ),
        _buildActionButton(
          icon: Icons.download,
          label: 'Download',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          NeumorphicContainer(
            width: 56,
            height: 56,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              icon,
              color: isActive
                  ? NeumorphicTheme.primaryAccent
                  : NeumorphicTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? NeumorphicTheme.primaryAccent
                  : NeumorphicTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongDetails() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Song Details',
            style: TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.album, 'Album', widget.song.album),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.category, 'Genre', widget.song.genre),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time,
            'Duration',
            _formatDuration(widget.song.duration),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Release Date',
            DateFormat('MMM d, yyyy').format(widget.song.releaseDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeumorphicTheme.primaryAccent.withOpacity(0.3),
                NeumorphicTheme.primaryAccent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: NeumorphicTheme.primaryAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: NeumorphicTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsSection() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lyrics',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _showLyrics = !_showLyrics);
                },
                child: Icon(
                  _showLyrics ? Icons.expand_less : Icons.expand_more,
                  color: NeumorphicTheme.primaryAccent,
                  size: 28,
                ),
              ),
            ],
          ),
          if (_showLyrics) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeumorphicTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Lyrics not available yet.\n\nThis feature will display synchronized lyrics when available.',
                style: TextStyle(
                  color: NeumorphicTheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarSongs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Similar Songs',
            style: TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.similarSongs!.length > 5 ? 5 : widget.similarSongs!.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final song = widget.similarSongs![index];
            return _buildSimilarSongItem(song);
          },
        ),
      ],
    );
  }

  Widget _buildSimilarSongItem(MusicModel song) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navigate to the new song page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SongPage(
              song: song,
              similarSongs: widget.similarSongs,
            ),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: song.imageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: NeumorphicTheme.cardColor,
                      child: const Icon(Icons.music_note, color: NeumorphicTheme.primaryAccent),
                    ),
                  )
                : Image.asset(
                    song.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: NeumorphicTheme.cardColor,
                        child: const Icon(Icons.music_note, color: NeumorphicTheme.primaryAccent),
                      );
                    },
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
                    color: NeumorphicTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: const TextStyle(
                    color: NeumorphicTheme.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(song.duration),
            style: const TextStyle(
              color: NeumorphicTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: NeumorphicTheme.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeumorphicTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'More Options',
              style: TextStyle(
                color: NeumorphicTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMoreOptionItem(Icons.person, 'View Artist', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Artist page coming soon!')),
              );
            }),
            const SizedBox(height: 12),
            _buildMoreOptionItem(Icons.album, 'View Album', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Album page coming soon!')),
              );
            }),
            const SizedBox(height: 12),
            _buildMoreOptionItem(Icons.queue_music, 'Add to Queue', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to queue!')),
              );
            }),
            const SizedBox(height: 12),
            _buildMoreOptionItem(Icons.radio, 'Go to Song Radio', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Song radio coming soon!')),
              );
            }),
            const SizedBox(height: 12),
            _buildMoreOptionItem(Icons.report, 'Report', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report feature coming soon!')),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: NeumorphicTheme.flatNeumorphicDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: NeumorphicTheme.primaryAccent),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: NeumorphicTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: NeumorphicTheme.textTertiary,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}


