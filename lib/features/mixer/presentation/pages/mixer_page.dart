import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/mix_model.dart';
import '../../../../data/services/mixer_service.dart';
import '../../../../core/config/api_config.dart';
import 'dart:math' as math;

class MixerPage extends StatefulWidget {
  const MixerPage({Key? key}) : super(key: key);

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _pulseController;

  // Generation state
  String _selectedMood = 'hype';
  String? _selectedGenre;
  int _songCount = 8;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _generateError;

  // Current mix
  MixModel? _currentMix;
  bool _mixSaved = false;

  // Playback state
  int _currentSongIndex = 0;
  bool _isPlayingTransition = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Saved mixes
  List<MixModel> _savedMixes = [];
  bool _showSavedMixes = false;

  static const _green = Color(0xFF10B981);
  static const _purple = Color(0xFF8B5CF6);
  static const _bg = Color(0xFF0F172A);

  final List<Map<String, dynamic>> _moods = [
    {'id': 'hype', 'label': 'Hype', 'emoji': '🔥'},
    {'id': 'party', 'label': 'Party', 'emoji': '🎉'},
    {'id': 'vibes', 'label': 'Vibes', 'emoji': '✨'},
    {'id': 'chill', 'label': 'Chill', 'emoji': '😌'},
    {'id': 'workout', 'label': 'Workout', 'emoji': '💪'},
    {'id': 'romance', 'label': 'Romance', 'emoji': '💕'},
    {'id': 'dancehall', 'label': 'Dancehall', 'emoji': '🎵'},
    {'id': 'reggae', 'label': 'Reggae', 'emoji': '🌴'},
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed && mounted) {
        _onTrackComplete();
      }
    });
    _player.positionStream.listen((p) { if (mounted) setState(() => _position = p); });
    _player.durationStream.listen((d) { if (mounted) setState(() => _duration = d ?? Duration.zero); });

    _loadSavedMixes();
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedMixes() async {
    try {
      final service = context.read<MixerService>();
      final mixes = await service.getMixes();
      if (mounted) setState(() => _savedMixes = mixes);
    } catch (_) {}
  }

  Future<void> _generateMix() async {
    setState(() { _isGenerating = true; _generateError = null; _currentMix = null; _mixSaved = false; });
    await _player.stop();

    try {
      final service = context.read<MixerService>();
      final mix = await service.generateMix(
        mood: _selectedMood,
        genre: _selectedGenre,
        songCount: _songCount,
      );
      setState(() {
        _currentMix = mix;
        _currentSongIndex = 0;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() { _isGenerating = false; _generateError = e.toString(); });
    }
  }

  Future<void> _saveMix() async {
    if (_currentMix == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final service = context.read<MixerService>();
      await service.saveMix(_currentMix!);
      setState(() { _mixSaved = true; _isSaving = false; });
      await _loadSavedMixes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mix saved! 🔥'), backgroundColor: _green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSavedMix(MixModel mix) async {
    if (mix.id == null) return;
    try {
      final service = context.read<MixerService>();
      await service.deleteMix(mix.id!);
      await _loadSavedMixes();
    } catch (_) {}
  }

  void _loadSavedMixForPlayback(MixModel mix) {
    setState(() {
      _currentMix = mix;
      _currentSongIndex = 0;
      _showSavedMixes = false;
      _mixSaved = true;
    });
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConfig.storageBaseUrl}$url';
  }

  Future<void> _playCurrentSong() async {
    final mix = _currentMix;
    if (mix == null || mix.songs.isEmpty) return;
    final song = mix.songs[_currentSongIndex];
    if (song.audioFile.isEmpty) return;

    // Play transition audio if available (intro = afterSongIndex 0, between = afterSongIndex == next song index)
    final transition = mix.transitions.where((t) => t.afterSongIndex == _currentSongIndex).firstOrNull;
    if (transition?.audioUrl != null && transition!.audioUrl!.isNotEmpty) {
      setState(() => _isPlayingTransition = true);
      try {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(transition.audioUrl!)));
        await _player.play();
        // Wait for transition to finish
        await _player.playerStateStream.firstWhere(
          (s) => s.processingState == ProcessingState.completed,
        );
      } catch (_) {}
      setState(() => _isPlayingTransition = false);
    }

    if (!mounted) return;
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(_resolveUrl(song.audioFile))));
      await _player.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  void _onTrackComplete() {
    if (_isPlayingTransition) return;
    final mix = _currentMix;
    if (mix == null) return;
    if (_currentSongIndex < mix.songs.length - 1) {
      setState(() => _currentSongIndex++);
      _playCurrentSong();
    } else {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else if (_player.audioSource == null) {
      _playCurrentSong();
    } else {
      _player.play();
    }
  }

  void _skipNext() {
    final mix = _currentMix;
    if (mix == null) return;
    if (_currentSongIndex < mix.songs.length - 1) {
      setState(() => _currentSongIndex++);
      _playCurrentSong();
    }
  }

  void _skipPrev() {
    if (_position.inSeconds > 3) {
      _player.seek(Duration.zero);
    } else if (_currentSongIndex > 0) {
      setState(() => _currentSongIndex--);
      _playCurrentSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDJStage(),
                  const SizedBox(height: 20),
                  _buildMoodSection(),
                  const SizedBox(height: 20),
                  _buildSongCountRow(),
                  const SizedBox(height: 20),
                  _buildGenerateButton(),
                  if (_generateError != null) ...[
                    const SizedBox(height: 12),
                    Text(_generateError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  if (_currentMix != null) ...[
                    const SizedBox(height: 24),
                    _buildMixHeader(),
                    const SizedBox(height: 12),
                    _buildMixQueue(),
                  ],
                  if (_showSavedMixes) ...[
                    const SizedBox(height: 24),
                    _buildSavedMixesList(),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _currentMix != null ? _buildBottomControls() : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: _green, size: 20),
          SizedBox(width: 8),
          Text('SELECTOR AI MIXER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_showSavedMixes ? Icons.close : Icons.library_music_outlined, color: Colors.white),
          onPressed: () => setState(() => _showSavedMixes = !_showSavedMixes),
          tooltip: 'Saved Mixes',
        ),
      ],
    );
  }

  Widget _buildDJStage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green.withOpacity(0.15), _purple.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 120 + 30 * _pulseController.value,
                height: 120 + 30 * _pulseController.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _green.withOpacity(0.25 * _pulseController.value), blurRadius: 40, spreadRadius: 20)],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎧', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(
                  _isGenerating ? 'Generating di mix...' :
                  _isPlayingTransition ? 'Selecta inna di dance! 🔥' :
                  _currentMix != null ? _currentMix!.mixName : 'Jamaican Selector Vibes',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(24, (i) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final h = (_isPlaying || _isGenerating)
                          ? 6 + 24 * math.Random(i + (_isGenerating ? DateTime.now().millisecond : 0)).nextDouble() * _pulseController.value
                          : 4.0;
                      return Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(color: _green.withOpacity(0.7), borderRadius: BorderRadius.circular(2)),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Vibe', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            final selected = _selectedMood == mood['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _green.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? _green : Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(mood['label'], style: TextStyle(color: selected ? _green : Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSongCountRow() {
    return Row(
      children: [
        const Text('Songs in mix:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(width: 16),
        ...[4, 6, 8, 10, 12].map((n) {
          final sel = _songCount == n;
          return GestureDetector(
            onTap: () => setState(() => _songCount = n),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: sel ? _green : Colors.white12),
              ),
              child: Center(child: Text('$n', style: TextStyle(color: sel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateMix,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Selecta ah work di magic... 🔥', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text('Generate Selector Mix', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
      ),
    );
  }

  Widget _buildMixHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentMix!.mixName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_currentMix!.songs.length} tracks · ${_selectedMood} vibe', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        if (!_mixSaved)
          TextButton.icon(
            onPressed: _isSaving ? null : _saveMix,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                : const Icon(Icons.bookmark_add_outlined, color: _green, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save Mix', style: const TextStyle(color: _green, fontSize: 13)),
          )
        else
          const Row(
            children: [
              Icon(Icons.bookmark, color: _green, size: 16),
              SizedBox(width: 4),
              Text('Saved', style: TextStyle(color: _green, fontSize: 13)),
            ],
          ),
      ],
    );
  }

  Widget _buildMixQueue() {
    final mix = _currentMix!;
    return Column(
      children: [
        ...mix.songs.asMap().entries.map((e) {
          final idx = e.key;
          final song = e.value;
          final isCurrent = idx == _currentSongIndex;

          // Find transition that plays before this song
          final transition = mix.transitions.where((t) => t.afterSongIndex == idx).firstOrNull;

          return Column(
            children: [
              if (transition != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎤', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transition.text,
                          style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                      if (transition.audioUrl != null)
                        const Icon(Icons.volume_up, color: Color(0xFFBB86FC), size: 14),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () {
                  setState(() => _currentSongIndex = idx);
                  _playCurrentSong();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? _green.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: isCurrent ? Border.all(color: _green.withOpacity(0.5)) : null,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.coverArt != null && song.coverArt!.isNotEmpty
                            ? CachedNetworkImage(imageUrl: _resolveUrl(song.coverArt!), width: 44, height: 44, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _fallbackArt())
                            : _fallbackArt(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isCurrent && _isPlaying)
                        const Icon(Icons.equalizer, color: _green, size: 20)
                      else
                        Text('${idx + 1}', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSavedMixesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saved Mixes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_savedMixes.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No saved mixes yet. Generate one!', style: TextStyle(color: Colors.white38)),
          ))
        else
          ..._savedMixes.map((mix) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Text('🎵', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mix.mixName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${mix.songs.length} tracks · ${mix.mood}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.play_circle, color: _green, size: 28), onPressed: () => _loadSavedMixForPlayback(mix)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20), onPressed: () => _deleteSavedMix(mix)),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildBottomControls() {
    final mix = _currentMix!;
    final currentSong = mix.songs.isNotEmpty ? mix.songs[_currentSongIndex] : null;
    final progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2435),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isPlayingTransition)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Color(0xFFBB86FC), size: 14),
                  SizedBox(width: 6),
                  Text('Selecta drop...', style: TextStyle(color: Color(0xFFBB86FC), fontSize: 12)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong?.name ?? 'No Track',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(currentSong?.artist ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white70), onPressed: _skipPrev),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 30),
                ),
              ),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white70), onPressed: _skipNext),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text('${_currentSongIndex + 1} / ${mix.songs.length}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackArt() => Container(
    width: 44, height: 44,
    color: Colors.white10,
    child: const Icon(Icons.music_note, color: Colors.white30, size: 20),
  );

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
