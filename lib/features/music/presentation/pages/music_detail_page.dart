import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/core/theme/neumorphic_theme.dart';
import 'package:intl/intl.dart';

class MusicDetailPage extends StatefulWidget {
  final MusicModel music;

  const MusicDetailPage({
    Key? key,
    required this.music,
  }) : super(key: key);

  @override
  _MusicDetailPageState createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
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
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: NeumorphicTheme.neumorphicDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: NeumorphicTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Now Playing',
                    style: TextStyle(
                      color: NeumorphicTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: NeumorphicTheme.neumorphicDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: NeumorphicTheme.primaryAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Album Art
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 80,
                decoration: NeumorphicTheme.neumorphicDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.music.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.music.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: NeumorphicTheme.surfaceColor,
                              child: const Icon(
                                Icons.music_note,
                                size: 80,
                                color: NeumorphicTheme.primaryAccent,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: NeumorphicTheme.surfaceColor,
                          child: const Icon(
                            Icons.music_note,
                            size: 80,
                            color: NeumorphicTheme.primaryAccent,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Song Title and Artist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Text(
                    widget.music.title,
                    style: const TextStyle(
                      color: NeumorphicTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.music.artist,
                    style: const TextStyle(
                      color: NeumorphicTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.music.album,
                    style: const TextStyle(
                      color: NeumorphicTheme.textTertiary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Music Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    icon: Icons.music_note,
                    label: 'Genre',
                    value: widget.music.genre,
                  ),
                  _buildInfoCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(widget.music.duration),
                  ),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Released',
                    value: DateFormat('yyyy').format(widget.music.releaseDate),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: NeumorphicTheme.primaryAccent,
                      inactiveTrackColor: NeumorphicTheme.surfaceColor,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: NeumorphicTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: NeumorphicTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Playback Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.skip_previous,
                    size: 32,
                    onPressed: () {
                      // Skip to previous track
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.replay_10,
                    size: 28,
                    onPressed: _skipBackward,
                  ),
                  _buildPlayPauseButton(),
                  _buildControlButton(
                    icon: Icons.forward_10,
                    size: 28,
                    onPressed: _skipForward,
                  ),
                  _buildControlButton(
                    icon: Icons.skip_next,
                    size: 32,
                    onPressed: () {
                      // Skip to next track
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: NeumorphicTheme.flatNeumorphicDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: NeumorphicTheme.primaryAccent,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: NeumorphicTheme.textTertiary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: NeumorphicTheme.neumorphicDecoration(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          icon,
          color: NeumorphicTheme.textPrimary,
          size: size,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        width: 72,
        height: 72,
        decoration: NeumorphicTheme.gradientNeumorphicDecoration(
          borderRadius: BorderRadius.circular(36),
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
      ),
    );
  }
}