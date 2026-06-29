import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/music_model.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/services/music_service.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'package:video_player/video_player.dart';
import 'neumorphic_button.dart';
import '../../shared/widgets/gift_bottom_sheet.dart';
import '../../shared/widgets/playlist_selection_bottom_sheet.dart';
import 'karaoke_lyrics_view.dart';

class PlayerScreen extends StatefulWidget {
  final MusicModel music;

  const PlayerScreen({
    Key? key,
    required this.music,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  bool _isFavorited = false;
  bool _karaokeMode = true;
  bool _lyricsExpanded = true;
  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  late AnimationController _bgAnimController;
  late AnimationController _entranceController;
  late Animation<double> _artEntrance;
  late Animation<double> _detailsEntrance;

  @override
  void initState() {
    super.initState();
    _lastVideoUrl = widget.music.videoUrl;
    _isFavorited = widget.music.isLiked;
    _initVideo(widget.music.videoUrl);

    // Slow ambient "breathing" zoom for the blurred album-art background.
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    // One-shot entrance: album art leads, title/controls follow slightly
    // behind — fires once when the sheet first opens, not on every track
    // change (those are handled by the existing AnimatedSwitcher instead).
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _artEntrance = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _detailsEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.currentMusic?.id != widget.music.id) {
        audioProvider.playMusic(widget.music);
      } else if (!audioProvider.isPlaying && audioProvider.currentMusic?.id == widget.music.id) {
        audioProvider.resume();
      }
      audioProvider.addListener(_onAudioProviderChanged);
    });
  }

  void _onAudioProviderChanged() {
    if (!mounted) return;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final currentMusic = audioProvider.currentMusic;
    if (currentMusic == null) return;

    final newVideoUrl = currentMusic.videoUrl;
    if (newVideoUrl != _lastVideoUrl) {
      _lastVideoUrl = newVideoUrl;
      _videoController?.dispose();
      _videoController = null;
      _initVideo(newVideoUrl);
    }
    
    // Sync favorited status
    if (_isFavorited != currentMusic.isLiked) {
      setState(() => _isFavorited = currentMusic.isLiked);
    }
  }

  void _initVideo(String videoUrl) {
    if (videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          _videoController?.setVolume(0.0);
          _videoController?.setLooping(true);
          _videoController?.play();
          if (mounted) setState(() {});
        }).catchError((e) {
          debugPrint("Video initialization failed: $e");
          _videoController = null;
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music.videoUrl != widget.music.videoUrl) {
      _videoController?.dispose();
      _videoController = null;
      _initVideo(widget.music.videoUrl);
    }
  }

  @override
  void dispose() {
    // Safe removal: only if context is still valid
    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      audioProvider.removeListener(_onAudioProviderChanged);
    } catch (_) {}
    _videoController?.dispose();
    _bgAnimController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, MusicModel>(
      selector: (context, provider) => provider.currentMusic ?? widget.music,
      builder: (context, currentMusic, child) {

        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              // Background Layer
              Positioned.fill(
                child: _videoController != null && _videoController!.value.isInitialized
                    ? Opacity(
                        opacity: 0.8,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      )
                    : _BlurredArtBackground(
                        imageUrl: currentMusic.imageUrl,
                        animation: _bgAnimController,
                      ),
              ),

              // Dark scrim so the blurred art blends into the background
              // instead of competing with the foreground text/icons.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // Foreground Layer
              SafeArea(
                child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 64,
                  leading: Padding(
                    // Extra clearance below the status bar/notch on top of the
                    // outer SafeArea — still reported as too tight on some
                    // devices at 10px, bumped for a clearly visible gap.
                    padding: const EdgeInsets.only(top: 20),
                    child: NeumorphicButton(
                      width: 44,
                      height: 44,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(Icons.keyboard_arrow_down, size: 28, color: NeumorphicTheme.textPrimary),
                    ),
                  ),
                  title: const Text(
                    'NOW PLAYING',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: NeumorphicTheme.textSecondary),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: IconButton(
                        onPressed: () => _shareSong(currentMusic),
                        icon: const Icon(Icons.share_outlined, color: NeumorphicTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Album Art
                          FadeTransition(
                            opacity: _artEntrance,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.85, end: 1.0).animate(_artEntrance),
                              child: Center(
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.75,
                                  height: MediaQuery.of(context).size.width * 0.75,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 30,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      currentMusic.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.music_note, size: 100, color: Colors.white24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Song Details
                          AnimatedBuilder(
                            animation: _detailsEntrance,
                            builder: (context, child) => FadeTransition(
                              opacity: _detailsEntrance,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - _detailsEntrance.value)),
                                child: child,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  currentMusic.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentMusic.artist,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          Consumer<AudioProvider>(
                            builder: (context, audioProvider, _) {
                              return Column(
                                children: [
                                  // Error Message
                                  if (audioProvider.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                audioProvider.errorMessage!,
                                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                          // Progress Bar
                          Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: const Color(0xFF10B981),
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: audioProvider.position.inSeconds.toDouble(),
                                  max: audioProvider.duration.inSeconds > 0
                                      ? audioProvider.duration.inSeconds.toDouble()
                                      : 1.0,
                                  onChanged: (value) => audioProvider.seek(Duration(seconds: value.toInt())),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(audioProvider.position),
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                                    Text(_formatDuration(audioProvider.duration),
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Playback Controls — shuffle / previous / play / next / repeat,
                          // all in one evenly-spaced row so every icon lines up consistently
                          // instead of shuffle/repeat floating off at the screen edges.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: audioProvider.toggleShuffle,
                                icon: Icon(
                                  Icons.shuffle,
                                  color: audioProvider.shuffle
                                      ? const Color(0xFF10B981)
                                      : Colors.white38,
                                  size: 22,
                                ),
                              ),
                              IconButton(
                                onPressed: audioProvider.previous,
                                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (audioProvider.isPlaying) {
                                    audioProvider.pause();
                                  } else {
                                    audioProvider.resume();
                                  }
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                  child: audioProvider.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Icon(
                                          audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                ),
                              ),
                              IconButton(
                                onPressed: audioProvider.next,
                                icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                              ),
                              IconButton(
                                onPressed: audioProvider.toggleRepeat,
                                icon: Icon(
                                  audioProvider.repeatMode == RepeatMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  color: audioProvider.repeatMode != RepeatMode.off
                                      ? const Color(0xFF10B981)
                                      : Colors.white38,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: () => _toggleFavorite(currentMusic),
                                icon: Icon(
                                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorited ? Colors.red : Colors.white60,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) => PlaylistSelectionBottomSheet(song: currentMusic),
                                  );
                                },
                                icon: const Icon(Icons.playlist_add, color: Colors.white60),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (currentMusic.artistId.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Artist info unavailable for this track')),
                                    );
                                    return;
                                  }
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => GiftBottomSheet(
                                      artistId: currentMusic.artistId,
                                      artistName: currentMusic.artist,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.card_giftcard, color: Colors.white60),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // Lyrics Section
                          if (currentMusic.lyrics.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _lyricsExpanded = !_lyricsExpanded),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lyrics_outlined, color: Color(0xFF10B981), size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          'LYRICS',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        if (currentMusic.lyricsLines != null &&
                                            currentMusic.lyricsLines!.isNotEmpty) ...[
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => setState(() => _karaokeMode = !_karaokeMode),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: _karaokeMode
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                                    : Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _karaokeMode
                                                      ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                                      : Colors.white.withValues(alpha: 0.15),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.mic_external_on,
                                                    size: 14,
                                                    color: _karaokeMode ? const Color(0xFF10B981) : Colors.white60,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'KARAOKE',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 1,
                                                      color: _karaokeMode ? const Color(0xFF10B981) : Colors.white60,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ] else
                                          const Spacer(),
                                        const SizedBox(width: 8),
                                        AnimatedRotation(
                                          turns: _lyricsExpanded ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 250),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.topCenter,
                                    child: !_lyricsExpanded
                                        ? const SizedBox(width: double.infinity)
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 20),
                                              if (_karaokeMode &&
                                                  currentMusic.lyricsLines != null &&
                                                  currentMusic.lyricsLines!.isNotEmpty)
                                                KaraokeLyricsView(lines: currentMusic.lyricsLines!)
                                              else
                                                Text(
                                                  currentMusic.lyrics,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.8),
                                                    fontSize: 18,
                                                    height: 1.8,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                             Center(
                               child: Text(
                                 'Lyrics not available for this track',
                                 style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                               ),
                             ),
                          ],
                          const SizedBox(height: 40),

                          // Up Next Section
                          Consumer<AudioProvider>(
                            builder: (context, audioProvider, _) {
                              if (audioProvider.queue.isEmpty) return const SizedBox();
                              return Column(
                                children: [
                                  Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Up Next',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...audioProvider.queue.skip(audioProvider.currentIndex + 1).take(3).toList().asMap().entries.map((entry) {
                              final int index = entry.key;
                              final song = entry.value;
                              final isNext = index == 0;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isNext ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isNext ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5) : null,
                                  boxShadow: isNext ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ] : null,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        song.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors.white10,
                                          child: const Icon(Icons.music_note, color: Colors.white38),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  song.title,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isNext)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'NEXT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song.artist,
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (audioProvider.queue.length - audioProvider.currentIndex - 1 > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '+ ${audioProvider.queue.length - audioProvider.currentIndex - 4} more',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                ),
                              ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),

              // Loading Splash Screen Overlay
              Consumer<AudioProvider>(
                builder: (context, audioProvider, child) {
                  if (!audioProvider.isLoading) return const SizedBox();
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: NeumorphicTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                color: Color(0xFF10B981),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Loading Track...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareSong(MusicModel music) {
    Share.share('Listening to ${music.title} by ${music.artist} on Lugmatic!');
  }

  Future<void> _toggleFavorite(MusicModel music) async {
    final musicService = context.read<MusicService>();
    try {
      await musicService.toggleFavorite(music.id, !_isFavorited);
      setState(() => _isFavorited = !_isFavorited);
    } catch (e) {
      debugPrint("Favorite toggle error: $e");
    }
  }
}

/// Heavily blurred, slowly "breathing" album-art background — fills the
/// screen behind the player so it feels alive without distracting from the
/// foreground controls. Crossfades smoothly when the track (and art) changes.
class _BlurredArtBackground extends StatelessWidget {
  final String imageUrl;
  final Animation<double> animation;

  const _BlurredArtBackground({required this.imageUrl, required this.animation});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: imageUrl.isEmpty
            ? _fallbackGradient(key: const ValueKey('fallback'))
            : AnimatedBuilder(
                key: ValueKey(imageUrl),
                animation: animation,
                builder: (context, child) {
                  final scale = 1.08 + (animation.value * 0.12);
                  return Transform.scale(
                    scale: scale,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45, tileMode: TileMode.decal),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackGradient(),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _fallbackGradient({Key? key}) => Container(
        key: key,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeumorphicTheme.backgroundColor,
              NeumorphicTheme.surfaceColor,
              NeumorphicTheme.backgroundColor,
            ],
          ),
        ),
      );
}
