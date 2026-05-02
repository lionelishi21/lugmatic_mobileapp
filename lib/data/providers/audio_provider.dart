import 'dart:math';
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
  final Random _random = Random();

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
  String? get errorMessage => _errorMessage;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;

  void toggleRepeat() {
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
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
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

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
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
      notifyListeners();
    });
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
      _currentMusic = music;
      _position = Duration.zero;
      _duration = Duration.zero;

      if (queue != null && queue.isNotEmpty) {
        _queue = queue;
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
        if (_currentIndex == -1) {
          // If the song isn't in the provided queue, just insert it and play it.
          _queue.insert(0, music);
          _currentIndex = 0;
        }
      } else if (_queue.any((m) => m.id == music.id)) {
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
      } else {
        // Essential fallback: If no queue is provided, make this single track the queue
        // so it doesn't break queue logic downstream.
        _queue = [music];
        _currentIndex = 0;
      }

      notifyListeners();

      final encodedUrl = music.audioUrl.trim().replaceAll(' ', '%20');

      final audioSource = AudioSource.uri(
        Uri.parse(encodedUrl),
        tag: MediaItem(
          id: music.id,
          album: music.album.isNotEmpty ? music.album : "Lugmatic",
          title: music.title,
          artist: music.artist,
          artUri: music.imageUrl.isNotEmpty
              ? Uri.parse(music.imageUrl.trim().replaceAll(' ', '%20'))
              : null,
        ),
      );

      // Async history trigger so we don't delay playback
      _musicService.recordPlay(music.id);

      await _audioPlayer.setAudioSource(audioSource);
      _audioPlayer.play();
    } catch (e) {
      _errorMessage = "Failed to load audio";
      debugPrint("Error playing music: $e");
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

  void next() {
    if (_queue.isEmpty) return;

    if (_shuffle && _queue.length > 1) {
      int newIndex;
      do {
        newIndex = _random.nextInt(_queue.length);
      } while (newIndex == _currentIndex);
      playMusic(_queue[newIndex]);
    } else if (_currentIndex < _queue.length - 1) {
      playMusic(_queue[_currentIndex + 1]);
    } else if (_repeatMode == RepeatMode.all) {
      playMusic(_queue[0]);
    }
  }

  void previous() {
    if (_queue.isEmpty) {
      seek(Duration.zero);
      return;
    }

    // If more than 3 seconds in, restart current track
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      playMusic(_queue[_currentIndex - 1]);
    } else if (_repeatMode == RepeatMode.all) {
      playMusic(_queue[_queue.length - 1]);
    } else {
      seek(Duration.zero);
    }
  }

  void _handlePlaybackCompleted() {
    if (_repeatMode == RepeatMode.one) {
      seek(Duration.zero).then((_) => resume());
    } else if (_shuffle && _queue.length > 1) {
      int newIndex;
      do {
        newIndex = _random.nextInt(_queue.length);
      } while (newIndex == _currentIndex);
      playMusic(_queue[newIndex]);
    } else if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      next();
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      playMusic(_queue[0]);
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
