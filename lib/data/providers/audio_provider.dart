import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/music_model.dart';
import '../services/music_service.dart';

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

    // Listen for errors
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
    _errorMessage = null; // Reset error

    // If already playing this song and it hasn't finished, just resume
    if (_currentMusic?.id == music.id && 
        _audioPlayer.processingState != ProcessingState.idle &&
        _audioPlayer.processingState != ProcessingState.completed) {
      resume();
      return;
    }

    // If it's the same song but it completed, seek to start and play
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
      
      if (queue != null) {
        _queue = queue;
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
      } else if (_queue.any((m) => m.id == music.id)) {
        // Update index if song is already in existing queue
        _currentIndex = _queue.indexWhere((m) => m.id == music.id);
      }
      
      notifyListeners();

      // Ensure URL is trimmed and spaces are encoded
      final encodedUrl = music.audioUrl.trim().replaceAll(' ', '%20');
      
      final audioSource = AudioSource.uri(
        Uri.parse(encodedUrl),
        tag: MediaItem(
          id: music.id,
          album: music.album.isNotEmpty ? music.album : "Lugmatic",
          title: music.title,
          artist: music.artist,
          artUri: music.imageUrl.isNotEmpty ? Uri.parse(music.imageUrl.trim().replaceAll(' ', '%20')) : null,
        ),
      );

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
    if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      playMusic(_queue[_currentIndex + 1]);
    }
  }

  void previous() {
    if (_queue.isNotEmpty && _currentIndex > 0) {
      playMusic(_queue[_currentIndex - 1]);
    } else {
      seek(Duration.zero);
    }
  }

  void _handlePlaybackCompleted() {
    if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      next();
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
