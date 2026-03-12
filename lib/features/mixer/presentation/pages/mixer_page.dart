import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/services/music_service.dart';
import 'package:lugmatic_flutter/core/theme/neumorphic_theme.dart';
import 'dart:math' as math;
import 'dart:async';

class MixerPage extends StatefulWidget {
  const MixerPage({Key? key}) : super(key: key);

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _avatarController;
  
  String _selectedMood = 'hype';
  String _selectedTempo = 'medium';
  double _bassGain = 0.5;
  double _echoAmount = 0.2;
  double _crossfadeSpeed = 3.0;
  
  List<MusicModel> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  
  final Map<String, double> _tempoMap = {
    'slow': 0.85,
    'medium': 1.0,
    'fast': 1.15,
    'turbo': 1.3,
  };

  final List<Map<String, dynamic>> _moods = [
    {'id': 'hype', 'label': 'Hype', 'emoji': '🔥'},
    {'id': 'party', 'label': 'Party', 'emoji': '🎉'},
    {'id': 'vibes', 'label': 'Vibes', 'emoji': '✨'},
    {'id': 'chill', 'label': 'Chill', 'emoji': '😌'},
    {'id': 'workout', 'label': 'Workout', 'emoji': '💪'},
    {'id': 'romance', 'label': 'Romance', 'emoji': '💕'},
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          _handleTrackEnded();
        }
      }
    });

    _loadInitialMix();
  }

  Future<void> _loadInitialMix() async {
    try {
      final musicService = context.read<MusicService>();
      final songs = await musicService.getSongs();
      if (mounted && songs.isNotEmpty) {
        setState(() {
          _queue = songs.take(8).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading initial mix: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _handleTrackEnded() {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _playCurrentTrack();
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_queue.isEmpty) return;
    
    final track = _queue[_currentIndex];
    final url = track.audioUrl;

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.setSpeed(_tempoMap[_selectedTempo] ?? 1.0);
      _player.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      if (_player.audioSource == null) {
        _playCurrentTrack();
      } else {
        _player.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDJStage(),
                  const SizedBox(height: 24),
                  _buildMoodSection(),
                  const SizedBox(height: 24),
                  _buildTempoAndEffects(),
                  const SizedBox(height: 24),
                  _buildQueueSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0F172A),
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 20),
          SizedBox(width: 8),
          Text(
            'AI MIXER',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDJStage() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Animated Background Pulse
          Center(
            child: AnimatedBuilder(
              animation: _avatarController,
              builder: (context, child) {
                return Container(
                  width: 150 + (30 * _avatarController.value),
                  height: 150 + (30 * _avatarController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2 * _avatarController.value),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // DJ Avatar Simple Visualization
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.headphones, size: 80, color: Colors.white),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _avatarController,
                  builder: (context, child) {
                    return Text(
                      _moods.firstWhere((m) => m['id'] == _selectedMood)['emoji'],
                      style: TextStyle(fontSize: 32 + (8 * _avatarController.value)),
                    );
                  },
                ),
              ],
            ),
          ),
          // Waveform Overlay (Mock)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(20, (index) {
                  return AnimatedBuilder(
                    animation: _avatarController,
                    builder: (context, child) {
                      final random = math.Random(index);
                      final height = 10 + (30 * random.nextDouble() * _avatarController.value);
                      return Container(
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
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
        const Text(
          'Select Mood',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _moods.length,
          itemBuilder: (context, index) {
            final mood = _moods[index];
            final isSelected = _selectedMood == mood['id'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedMood = mood['id']);
                // Logic to filter queue would go here
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(mood['emoji'], style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      mood['label'],
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTempoAndEffects() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tempo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._tempoMap.keys.map((t) {
                final isSelected = _selectedTempo == t;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTempo = t);
                    _player.setSpeed(_tempoMap[t]!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        t.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Effects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildEffectSlider('Bass Boost', _bassGain, (v) => setState(() => _bassGain = v)),
              _buildEffectSlider('Echo', _echoAmount, (v) => setState(() => _echoAmount = v)),
              _buildEffectSlider('Crossfade', _crossfadeSpeed / 10, (v) => setState(() => _crossfadeSpeed = v * 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF10B981),
          inactiveColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mix Queue',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_queue.length}/8',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_queue.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('Add songs to start mixing', style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ..._queue.asMap().entries.map((entry) {
            final idx = entry.key;
            final song = entry.value;
            final isCurrent = idx == _currentIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF10B981).withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: isCurrent ? Border.all(color: const Color(0xFF10B981).withOpacity(0.5)) : null,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(song.artist, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isCurrent && _isPlaying)
                    const Icon(Icons.equalizer, color: Color(0xFF10B981), size: 20),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOW MIXING', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SizedBox(
                width: 150,
                child: Text(
                  _queue.isEmpty ? 'No Track Selected' : _queue[_currentIndex].title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.shuffle, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _queue.shuffle();
                  });
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white70),
                onPressed: _handleTrackEnded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
