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

  // Bumped on every playMusic() call so an in-flight call that gets
  // superseded by a newer one (e.g. a quick second tap, or the player
  // screen's own initState racing a list item's tap) can tell it's been
  // overtaken and silently bail instead of reporting a false failure —
  // setAudioSources() on the same player doesn't handle two concurrent
  // calls gracefully, and the loser throws even though the winner plays
  // fine.
  int _playRequestGeneration = 0;

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

  /// One malformed audioUrl in a long list (e.g. a paginated genre/category
  /// feed) must not take down the whole queue load — setAudioSources()
  /// builds AudioSources for every item up front, so a single bad entry
  /// throwing during URI parsing previously surfaced as "Failed to load
  /// audio" even for the track the user actually tapped, which was fine.
  bool _hasParseableAudioUrl(MusicModel music) {
    if (music.audioUrl.trim().isEmpty) return false;
    try {
      _safeParseUri(music.audioUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> playMusic(MusicModel music, {List<MusicModel>? queue}) async {
    // Claimed before any early return so a still-in-flight older call (see
    // below) is reliably recognized as superseded the moment ANY new call
    // comes in, including ones that just resume/seek instead of reloading.
    final myGeneration = ++_playRequestGeneration;
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
        _queue = queue.where(_hasParseableAudioUrl).toList();
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
        if (_currentIndex == -1) {
          // If the song isn't in the provided queue, just insert it and play it.
          if (!_hasParseableAudioUrl(music)) {
            throw Exception("Cannot play track: Audio URL is missing or invalid.");
          }
          _queue.insert(0, music);
          _currentIndex = 0;
        }
      } else if (_queue.any((m) => m.id == music.id)) {
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
      } else {
        if (!_hasParseableAudioUrl(music)) {
          throw Exception("Cannot play track: Audio URL is missing or invalid.");
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
      //
      // The very first request into a freshly opened screen can hit a cold
      // TLS/DNS connection to the media host and time out even though the
      // URL itself is perfectly valid — the same tap immediately after
      // (warm connection) succeeds. One silent retry absorbs that instead
      // of showing "Failed to load audio" for something that isn't broken.
      Object? loadError;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          await _audioPlayer.setAudioSources(
            _queue.map(_toAudioSource).toList(),
            initialIndex: _currentIndex,
            initialPosition: Duration.zero,
          );
          loadError = null;
          break;
        } catch (e) {
          loadError = e;
          if (attempt == 0) {
            debugPrint("First setAudioSources attempt failed, retrying: $e");
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      if (loadError != null) throw loadError;

      // A newer playMusic() call already took over the player while this
      // one was loading — let it own the state instead of stomping on it.
      if (myGeneration != _playRequestGeneration) return;

      await _audioPlayer.setShuffleModeEnabled(_shuffle);
      await _audioPlayer.setLoopMode(switch (_repeatMode) {
        RepeatMode.off => LoopMode.off,
        RepeatMode.all => LoopMode.all,
        RepeatMode.one => LoopMode.one,
      });
      _musicService.recordPlay(music.id);
      _audioPlayer.play();
    } catch (e) {
      // Same check here: setAudioSources() doesn't handle two concurrent
      // calls on one AudioPlayer gracefully, so the call that loses a race
      // against a newer one throws even though the winner is now playing
      // fine. Only surface the failure if this is still the latest request.
      if (myGeneration != _playRequestGeneration) return;
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
      if (myGeneration == _playRequestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Updates the liked state on the currently-playing track (and its entry
  /// in the queue) after a like/unlike call succeeds. Without this, the
  /// Now Playing screen's own provider-change listener — which fires on
  /// every position tick — kept seeing its optimistic local toggle as "out
  /// of sync" with this stale cached model and immediately reverted it,
  /// making the heart button look like it doesn't do anything.
  void updateCurrentMusicLikedState(String musicId, bool isLiked) {
    if (_currentMusic?.id == musicId) {
      _currentMusic!.isLiked = isLiked;
    }
    final idx = _queue.indexWhere((m) => m.id == musicId);
    if (idx != -1) {
      _queue[idx].isLiked = isLiked;
    }
    notifyListeners();
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
