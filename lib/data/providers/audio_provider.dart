import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/music_model.dart';
import '../services/music_service.dart';

enum RepeatMode { off, all, one }

class AudioProvider extends ChangeNotifier {
  final MusicService _musicService;
  late AudioPlayer _audioPlayer;

  MusicModel? _currentMusic;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<MusicModel> _queue = [];
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;

  String? _errorMessage;

  AudioProvider({required MusicService musicService}) : _musicService = musicService {
    _audioPlayer = AudioPlayer();
    _initListeners();
  }

  MusicModel? get currentMusic => _currentMusic;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  List<MusicModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  String? get errorMessage => _errorMessage;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;

  Future<void> toggleRepeat() async {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    await _audioPlayer.setLoopMode(switch (_repeatMode) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    await _audioPlayer.setShuffleModeEnabled(_shuffle);
    if (_shuffle) {
      await _audioPlayer.shuffle();
    }
    notifyListeners();
  }

  void _initListeners() {
    _audioPlayer.durationStream.listen((d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });

    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });

    // Fires for every track change in the sequence — in-app taps, lock-screen
    // skip-next/previous, and natural end-of-track advance all flow through here.
    _audioPlayer.currentIndexStream.listen((index) {
      if (index == null || _queue.isEmpty || index < 0 || index >= _queue.length) return;
      if (_currentIndex == index && _currentMusic?.id == _queue[index].id) return;
      _currentIndex = index;
      _currentMusic = _queue[index];
      _musicService.recordPlay(_currentMusic!.id);
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();
    });

    _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      if (e is PlayerException) {
        _errorMessage = "Error: ${e.message}";
      } else if (e is PlayerInterruptedException) {
        _errorMessage = "Playback interrupted";
      } else {
        _errorMessage = "An unknown error occurred";
      }
      debugPrint("Player Error: $e");
      // A load/playback error can leave the native player wedged (still
      // "loading" with no further events), which blocks every subsequent
      // setAudioSources() call. Force it back to idle so the next track
      // the user taps gets a clean player instead of inheriting this state.
      _resetPlayerAfterError();
    });
  }

  Future<void> _resetPlayerAfterError() async {
    _isLoading = false;
    _isPlaying = false;
    _currentMusic = null;
    _currentIndex = -1;
    notifyListeners();
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Error resetting player after failure: $e");
    }
  }

  /// Parse a URL that's already supposed to be valid (ApiConfig.resolveUrl
  /// already resolves relative paths to full URLs). Try parsing it as-is
  /// first — Uri.encodeFull on an already-valid URL double-encodes any
  /// existing "%" escape (e.g. "%2B" -> "%252B"), which 404s. Only fall back
  /// to encoding if the raw string genuinely isn't parseable (e.g. literal
  /// unencoded spaces).
  Uri _safeParseUri(String url) {
    final trimmed = url.trim();
    final direct = Uri.tryParse(trimmed);
    if (direct != null && direct.hasScheme && direct.host.isNotEmpty) {
      return direct;
    }
    return Uri.parse(Uri.encodeFull(trimmed));
  }

  AudioSource _toAudioSource(MusicModel music) {
    return AudioSource.uri(
      _safeParseUri(music.audioUrl),
      tag: MediaItem(
        id: music.id,
        album: music.album.isNotEmpty ? music.album : "Lugmatic",
        title: music.title,
        artist: music.artist,
        artUri: music.imageUrl.isNotEmpty ? _safeParseUri(music.imageUrl) : null,
      ),
    );
  }

  Future<void> playMusic(MusicModel music, {List<MusicModel>? queue}) async {
    _errorMessage = null;

    if (_currentMusic?.id == music.id &&
        _audioPlayer.processingState != ProcessingState.idle &&
        _audioPlayer.processingState != ProcessingState.completed) {
      resume();
      return;
    }

    if (_currentMusic?.id == music.id && _audioPlayer.processingState == ProcessingState.completed) {
      await seek(Duration.zero);
      resume();
      return;
    }

    try {
      _isLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;

      if (queue != null && queue.isNotEmpty) {
        _queue = queue.where((m) => m.audioUrl.trim().isNotEmpty).toList();
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
        if (_currentIndex == -1) {
          // If the song isn't in the provided queue, just insert it and play it.
          if (music.audioUrl.trim().isEmpty) {
            throw Exception("Cannot play track: Audio URL is missing.");
          }
          _queue.insert(0, music);
          _currentIndex = 0;
        }
      } else if (_queue.any((m) => m.id == music.id)) {
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
      } else {
        if (music.audioUrl.trim().isEmpty) {
          throw Exception("Cannot play track: Audio URL is missing.");
        }
        // Essential fallback: If no queue is provided, make this single track the queue
        // so it doesn't break queue logic downstream.
        _queue = [music];
        _currentIndex = 0;
      }

      _currentMusic = music;
      notifyListeners();

      // Real sequence (not a single swapped-out source) — this is what lets
      // just_audio_background report hasNext/hasPrevious to the OS, which is
      // what makes skip-next/previous actually show up in the lock-screen /
      // notification media controls.
      await _audioPlayer.setAudioSources(
        _queue.map(_toAudioSource).toList(),
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await _audioPlayer.setShuffleModeEnabled(_shuffle);
      await _audioPlayer.setLoopMode(switch (_repeatMode) {
        RepeatMode.off => LoopMode.off,
        RepeatMode.all => LoopMode.all,
        RepeatMode.one => LoopMode.one,
      });
      _musicService.recordPlay(music.id);
      _audioPlayer.play();
    } catch (e) {
      _errorMessage = "Failed to load audio";
      debugPrint("Error playing music: $e");
      _currentMusic = null;
      _currentIndex = -1;
      try {
        await _audioPlayer.stop();
      } catch (stopError) {
        debugPrint("Error resetting player after failed load: $stopError");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void resume() {
    _audioPlayer.play();
  }

  void stop() {
    _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentMusic = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> previous() async {
    // If more than 3 seconds in, restart current track instead of skipping back.
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
