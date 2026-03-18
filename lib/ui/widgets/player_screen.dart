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

class PlayerScreen extends StatefulWidget {
  final MusicModel music;

  const PlayerScreen({
    Key? key,
    required this.music,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isFavorited = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    // Start playing if not already playing this song
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.currentMusic?.id != widget.music.id) {
        audioProvider.playMusic(widget.music);
      } else if (!audioProvider.isPlaying && audioProvider.currentMusic?.id == widget.music.id) {
        audioProvider.resume();
      }
    });

    _initVideo();
  }

  void _initVideo() {
    if (widget.music.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.music.videoUrl))
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
      _initVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentMusic = audioProvider.currentMusic ?? widget.music;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.black, // fallback
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
                    : Container(
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
                      ),
              ),

              // Foreground Layer
              Scaffold(
                backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Center(
                child: NeumorphicButton(
                  width: 44,
                  height: 44,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.keyboard_arrow_down, size: 28, color: NeumorphicTheme.textPrimary),
                ),
              ),
              title: const Text('NOW PLAYING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: NeumorphicTheme.textSecondary)),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => _shareSong(currentMusic),
                  icon: const Icon(Icons.share_outlined, color: NeumorphicTheme.textPrimary),
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
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
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
                      const SizedBox(height: 40),
                      
                      // Song Details
                      Column(
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
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Error Message
                      if (audioProvider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                                Text(_formatDuration(audioProvider.position), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                Text(_formatDuration(audioProvider.duration), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: audioProvider.previous,
                            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
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
                              child: Icon(
                                audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: audioProvider.next,
                            icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Secondary Controls
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
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_horiz, color: Colors.white60),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
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
