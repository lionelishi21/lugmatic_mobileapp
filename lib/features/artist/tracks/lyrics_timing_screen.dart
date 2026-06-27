import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/artist/upload_service.dart';

/// Produces karaoke timing data the fan-facing Now Playing screen uses to
/// highlight lyrics in sync with playback. Primary path: "Auto-Generate with
/// AI" calls the backend (Gemini, falling back to Transcribe+Bedrock) to
/// pre-fill every line; the artist can review and re-record any individual
/// line, or fall back entirely to tapping each line in sync with playback.
class LyricsTimingScreen extends StatefulWidget {
  final String songId;
  final String lyrics;
  final File audioFile;
  final UploadService uploadService;

  const LyricsTimingScreen({
    super.key,
    required this.songId,
    required this.lyrics,
    required this.audioFile,
    required this.uploadService,
  });

  @override
  State<LyricsTimingScreen> createState() => _LyricsTimingScreenState();
}

class _LyricsTimingScreenState extends State<LyricsTimingScreen> {
  final _player = AudioPlayer();

  late final List<String> _lines;
  late List<Map<String, dynamic>?> _stamped;
  int? _recordTarget;
  bool _isPlaying = false;
  bool _isSaving = false;
  bool _isLoadingAudio = true;
  bool _isGenerating = false;
  String? _source;
  String? _generateError;

  @override
  void initState() {
    super.initState();
    _lines = widget.lyrics
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    _stamped = List<Map<String, dynamic>?>.filled(_lines.length, null, growable: false);
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setFilePath(widget.audioFile.path);
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _isPlaying = state.playing);
      });
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  int? _nextUnstampedIndex() {
    for (var i = 0; i < _stamped.length; i++) {
      if (_stamped[i] == null) return i;
    }
    return null;
  }

  void _stampCurrentLine() {
    final target = _recordTarget ?? _nextUnstampedIndex();
    if (target == null) return;
    setState(() {
      _stamped[target] = {
        'time': _player.position.inMilliseconds / 1000.0,
        'text': _lines[target],
      };
      _recordTarget = null;
    });
    if (_nextUnstampedIndex() == null) {
      _player.pause();
    }
  }

  void _startRerecord(int index) {
    final existing = _stamped[index];
    setState(() => _recordTarget = index);
    final existingSeconds = (existing?['time'] as num?)?.toDouble() ?? 0.0;
    final seekTo = Duration(milliseconds: (existingSeconds * 1000).round());
    final lookback = const Duration(seconds: 2);
    _player.seek(seekTo > lookback ? seekTo - lookback : Duration.zero);
  }

  Future<void> _autoGenerate() async {
    setState(() {
      _isGenerating = true;
      _generateError = null;
    });
    try {
      final (lyricsLines, source) = await widget.uploadService.autoGenerateLyricsTiming(widget.songId);
      setState(() {
        for (var i = 0; i < _stamped.length; i++) {
          if (i < lyricsLines.length) {
            _stamped[i] = {
              'time': (lyricsLines[i]['time'] as num).toDouble(),
              'text': _lines[i],
            };
          }
        }
        _source = source;
        _recordTarget = null;
      });
    } catch (e) {
      setState(() => _generateError = 'AI generation failed: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final lines = _stamped.whereType<Map<String, dynamic>>().toList();
      await widget.uploadService.updateSongLyricsTiming(widget.songId, lines);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karaoke timing saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save timing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'gemini':
        return 'Aligned with Gemini';
      case 'transcribe-bedrock':
        return 'Aligned via Transcribe + Bedrock fallback';
      default:
        return 'Aligned with AI';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = _recordTarget ?? _nextUnstampedIndex();
    final isDone = nextIndex == null;
    final stampedCount = _stamped.where((s) => s != null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Add Karaoke Timing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _lines.isEmpty
          ? const Center(
              child: Text('No lyrics to time.', style: TextStyle(color: AppColors.mutedForeground)),
            )
          : _isLoadingAudio
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isGenerating ? null : _autoGenerate,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            _isGenerating ? 'Generating...' : 'Auto-Generate with AI',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_source != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _sourceLabel(_source!),
                            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                          ),
                        ),
                      if (_generateError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _generateError!,
                            style: const TextStyle(color: AppColors.destructive, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '$stampedCount / ${_lines.length} lines timed',
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _lines.length,
                          itemBuilder: (context, index) {
                            final stamp = _stamped[index];
                            final isStamped = stamp != null;
                            final isActive = index == nextIndex;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive
                                    ? Border.all(color: AppColors.primary, width: 1.5)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isStamped ? Icons.check_circle : Icons.circle_outlined,
                                    size: 18,
                                    color: isStamped ? AppColors.primary : AppColors.mutedForeground,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _lines[index],
                                      style: TextStyle(
                                        color: isActive ? AppColors.foreground : AppColors.mutedForeground,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isStamped)
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.mutedForeground),
                                      tooltip: 'Re-record this line',
                                      onPressed: () => _startRerecord(index),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            iconSize: 36,
                            color: AppColors.primary,
                            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                            onPressed: _togglePlayback,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDone ? AppColors.muted : AppColors.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: isDone ? null : _stampCurrentLine,
                                child: Text(
                                  isDone ? 'All lines timed' : 'Tap on "${_lines[nextIndex]}"',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (stampedCount == 0 || _isSaving) ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Text('Save Timing', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
