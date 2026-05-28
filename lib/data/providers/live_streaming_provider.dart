import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/live_stream_service.dart';
import '../services/socket_service.dart';

class LiveStreamingProvider extends ChangeNotifier {
  final LiveStreamService _liveService;
  final SocketService _socketService;

  LiveStreamingProvider({
    required LiveStreamService liveService,
    required SocketService socketService,
  })  : _liveService = liveService,
        _socketService = socketService;

  bool _isStreaming = false;
  bool _isBusy = false;
  Room? _room;
  String? _streamId;
  Map<String, dynamic>? _summary;

  final List<Map<String, dynamic>> _messages = [];
  int _viewerCount = 0;
  int _totalCoins = 0;
  DateTime? _liveSince;
  Timer? _timer;
  String _elapsedTime = '0:00';

  bool _isMicOn = true;
  bool _isCameraOn = true;
  Map<String, dynamic>? _lastGift;
  Map<String, dynamic>? _activeClash;
  String? _clashRoomUrl;
  String? _clashRoomToken;
  String? _clashChallengerUserId;
  String? _clashOpponentUserId;

  StreamSubscription? _chatSub;
  StreamSubscription? _giftSub;
  StreamSubscription? _viewerSub;
  StreamSubscription? _clashInvSub;
  StreamSubscription? _clashStartSub;
  StreamSubscription? _clashScoreSub;
  StreamSubscription? _clashEndSub;

  bool get isStreaming => _isStreaming;
  bool get isBusy => _isBusy;
  Room? get room => _room;
  String? get streamId => _streamId;
  Map<String, dynamic>? get summary => _summary;
  List<Map<String, dynamic>> get messages => _messages;
  int get viewerCount => _viewerCount;
  int get totalCoins => _totalCoins;
  String get elapsedTime => _elapsedTime;
  bool get isMicOn => _isMicOn;
  bool get isCameraOn => _isCameraOn;
  Map<String, dynamic>? get lastGift => _lastGift;
  Map<String, dynamic>? get activeClash => _activeClash;
  String? get clashRoomUrl => _clashRoomUrl;
  String? get clashRoomToken => _clashRoomToken;
  String? get clashChallengerUserId => _clashChallengerUserId;
  String? get clashOpponentUserId => _clashOpponentUserId;
  bool get hasClashRoom => _clashRoomToken != null && _clashRoomUrl != null;

  Stream<Map<String, dynamic>> get clashInvitations => _socketService.onClashInvitation;

  void clearSummary() {
    _summary = null;
    notifyListeners();
  }

  Future<void> startStreaming(String title, {String? description, String? category}) async {
    _isBusy = true;
    notifyListeners();

    try {
      final stream = await _liveService.createStream(
        title: title,
        description: description,
        category: category,
      );
      _streamId = stream.id;

      final tokenData = await _liveService.getStreamToken(_streamId!);

      _room = Room();
      await _room!.connect(tokenData.url, tokenData.token);

      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _setupSocketListeners(_streamId!);
      _liveSince = DateTime.now();
      _startTimer();

      _isStreaming = true;
      _isBusy = false;
      _summary = null;
      notifyListeners();
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      rethrow;
    }
  }

  void _setupSocketListeners(String streamId) {
    _cancelSubscriptions();

    _chatSub = _socketService.onChatMessage.listen((msg) {
      _messages.add({
        'username': msg.username,
        'message': msg.message,
        'type': msg.type,
      });
      notifyListeners();
    });

    _giftSub = _socketService.onGiftReceived.listen((gift) {
      _totalCoins += (gift['giftValue'] as num?)?.toInt() ?? 0;
      _lastGift = gift;
      notifyListeners();

      Future.delayed(const Duration(seconds: 4), () {
        if (_lastGift == gift) {
          _lastGift = null;
          notifyListeners();
        }
      });
    });

    _viewerSub = _socketService.onViewerCountChanged.listen((count) {
      _viewerCount = count;
      notifyListeners();
    });

    _clashInvSub = _socketService.onClashInvitation.listen((_) {});

    _clashStartSub = _socketService.onClashStarted.listen((data) {
      _activeClash = data;
      final room = data['clashRoom'] as Map<String, dynamic>?;
      if (room != null) {
        _clashRoomUrl = room['url'] as String?;
        _clashRoomToken = room['token'] as String?;
      }
      _clashChallengerUserId = data['challengerUserId'] as String?;
      _clashOpponentUserId = data['opponentUserId'] as String?;
      notifyListeners();
    });

    _clashScoreSub = _socketService.onClashScoreUpdate.listen((data) {
      if (_activeClash != null) {
        _activeClash!['challengerScore'] = data['challengerScore'];
        _activeClash!['opponentScore'] = data['opponentScore'];
        notifyListeners();
      }
    });

    _clashEndSub = _socketService.onClashEnded.listen((_) {
      _activeClash = null;
      _clashRoomToken = null;
      _clashRoomUrl = null;
      notifyListeners();
    });

    _socketService.joinStream(streamId);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_liveSince != null) {
        _elapsedTime = _formatDuration(DateTime.now().difference(_liveSince!));
        notifyListeners();
      }
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${d.inMinutes}:${two(d.inSeconds.remainder(60))}';
  }

  Future<void> stopStreaming() async {
    if (_streamId == null) return;
    _isBusy = true;
    notifyListeners();

    try {
      await _liveService.endStream(_streamId!);
      await _room?.disconnect();
      _socketService.leaveStream(_streamId!);
      _timer?.cancel();

      _summary = {
        'duration': DateTime.now().difference(_liveSince ?? DateTime.now()).inSeconds,
        'totalViewers': _viewerCount,
        'totalGiftsReceived': _messages.where((m) => m['type'] == 'gift').length,
        'totalGiftValue': _totalCoins,
      };

      _isStreaming = false;
      _isBusy = false;
      _room = null;
      _messages.clear();
      _viewerCount = 0;
      _totalCoins = 0;
      _activeClash = null;
      _elapsedTime = '0:00';
      _liveSince = null;
      notifyListeners();
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMic() async {
    if (_room == null) return;
    _isMicOn = !_isMicOn;
    await _room!.localParticipant?.setMicrophoneEnabled(_isMicOn);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (_room == null) return;
    _isCameraOn = !_isCameraOn;
    await _room!.localParticipant?.setCameraEnabled(_isCameraOn);
    notifyListeners();
  }

  void sendChat(String message) {
    if (_streamId == null || message.trim().isEmpty) return;
    _socketService.sendChat(_streamId!, message.trim());
  }

  Future<void> acceptClash(String clashId) async {
    await _liveService.acceptClash(clashId);
  }

  Future<void> rejectClash(String clashId) async {
    await _liveService.rejectClash(clashId);
  }

  void _cancelSubscriptions() {
    _chatSub?.cancel();
    _giftSub?.cancel();
    _viewerSub?.cancel();
    _clashInvSub?.cancel();
    _clashStartSub?.cancel();
    _clashScoreSub?.cancel();
    _clashEndSub?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelSubscriptions();
    _room?.disconnect();
    super.dispose();
  }
}
