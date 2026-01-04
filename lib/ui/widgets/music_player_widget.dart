import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/music_model.dart';
import '../../core/theme/neumorphic_theme.dart';

class MusicPlayerWidget extends StatefulWidget {
  final MusicModel music;
  final VoidCallback? onClose;

  const MusicPlayerWidget({
    Key? key,
    required this.music,
    this.onClose,
  }) : super(key: key);

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
        }
      });

      // Load the audio
      await _audioPlayer.setUrl(widget.music.audioUrl);
      setState(() => _isLoading = false);
      
      // Auto-play
      _audioPlayer.play();
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
    final newPosition = _position + const Duration(seconds: 10);
    _audioPlayer.seek(newPosition < _duration ? newPosition : _duration);
  }

  void _skipBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    _audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: NeumorphicButton(
            width: 50,
            height: 50,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(15),
            onPressed: widget.onClose ?? () => Navigator.pop(context),
            child: const Icon(Icons.keyboard_arrow_down, size: 28, color: NeumorphicTheme.textPrimary),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: NeumorphicButton(
                width: 50,
                height: 50,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(15),
                onPressed: () {
                  // Show more options
                },
                child: const Icon(Icons.more_vert, size: 24, color: NeumorphicTheme.textPrimary),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Album Art
                Expanded(
                  child: Center(
                    child: NeumorphicContainer(
                      width: 320,
                      height: 320,
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(30),
                      color: NeumorphicTheme.surfaceColor,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.music.imageUrl.startsWith('http')
                            ? Image.network(
                                widget.music.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderArt();
                                },
                              )
                            : Image.asset(
                                widget.music.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderArt();
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Song Info
                Column(
                  children: [
                    Text(
                      widget.music.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.music.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Progress Bar
                Column(
                  children: [
                    NeumorphicContainer(
                      isConcave: true,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      borderRadius: BorderRadius.circular(20),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NeumorphicButton(
                      width: 50,
                      height: 50,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(15),
                      onPressed: () {
                        // Implement shuffle
                      },
                      child: Icon(
                        Icons.shuffle,
                        color: NeumorphicTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                    NeumorphicButton(
                      width: 60,
                      height: 60,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: () {
                        // Implement previous song
                      },
                      child: Icon(
                        Icons.skip_previous,
                        color: NeumorphicTheme.textPrimary,
                        size: 32,
                      ),
                    ),
                    _isLoading
                        ? NeumorphicContainer(
                            width: 75,
                            height: 75,
                            padding: const EdgeInsets.all(18),
                            borderRadius: BorderRadius.circular(22),
                            color: NeumorphicTheme.surfaceColor,
                            child: CircularProgressIndicator(
                              color: NeumorphicTheme.primaryAccent,
                              strokeWidth: 3,
                            ),
                          )
                        : NeumorphicButton(
                            width: 75,
                            height: 75,
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(22),
                            isGradient: true,
                            gradientColors: [
                              NeumorphicTheme.accentGradientStart,
                              NeumorphicTheme.accentGradientEnd,
                            ],
                            onPressed: _playPause,
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                    NeumorphicButton(
                      width: 60,
                      height: 60,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: () {
                        // Implement next song
                      },
                      child: Icon(
                        Icons.skip_next,
                        color: NeumorphicTheme.textPrimary,
                        size: 32,
                      ),
                    ),
                    NeumorphicButton(
                      width: 50,
                      height: 50,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(15),
                      onPressed: () {
                        // Implement repeat
                      },
                      child: Icon(
                        Icons.repeat,
                        color: NeumorphicTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Additional Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NeumorphicButton(
                      width: 55,
                      height: 55,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _skipBackward,
                      child: Icon(
                        Icons.replay_10,
                        color: NeumorphicTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                    NeumorphicButton(
                      width: 55,
                      height: 55,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        // Implement favorite
                      },
                      child: Icon(
                        Icons.favorite_border,
                        color: NeumorphicTheme.primaryAccent,
                        size: 26,
                      ),
                    ),
                    NeumorphicButton(
                      width: 55,
                      height: 55,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _skipForward,
                      child: Icon(
                        Icons.forward_10,
                        color: NeumorphicTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: const Color(0xFF1F2937),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 120,
          color: const Color(0xFFA855F7).withOpacity(0.5),
        ),
      ),
    );
  }
}

