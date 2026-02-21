import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/api_config.dart';
import '../../core/network/token_storage.dart';
import '../models/live_stream_model.dart';

/// Singleton Socket.io service for real-time live stream features.
///
/// Handles: chat messages, gift events, viewer join/leave, typing, reactions.
class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  final TokenStorage _tokenStorage;
  String? _currentStreamId;

  // ── Stream controllers for real-time events ──────────────────────

  final _chatController =
      StreamController<LiveStreamChatMessage>.broadcast();
  final _giftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _viewerJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _viewerLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _viewerCountController = StreamController<int>.broadcast();
  final _streamEndedController = StreamController<void>.broadcast();
  final _reactionController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Real-time chat messages.
  Stream<LiveStreamChatMessage> get onChatMessage => _chatController.stream;

  /// Gift received events.
  Stream<Map<String, dynamic>> get onGiftReceived => _giftController.stream;

  /// Viewer joined events.
  Stream<Map<String, dynamic>> get onViewerJoined =>
      _viewerJoinedController.stream;

  /// Viewer left events.
  Stream<Map<String, dynamic>> get onViewerLeft =>
      _viewerLeftController.stream;

  /// Updated viewer count.
  Stream<int> get onViewerCountChanged => _viewerCountController.stream;

  /// Stream ended event.
  Stream<void> get onStreamEnded => _streamEndedController.stream;

  /// Reaction events.
  Stream<Map<String, dynamic>> get onReaction => _reactionController.stream;

  SocketService._({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  /// Get the singleton instance.
  static SocketService getInstance({required TokenStorage tokenStorage}) {
    _instance ??= SocketService._(tokenStorage: tokenStorage);
    return _instance!;
  }

  /// Connect to the Socket.io server.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _tokenStorage.getAccessToken();

    // Socket connects directly to EC2 (not through CloudFront)
    final socketUrl = ApiConfig.socketUrl;

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token ?? ''})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error: $err');
    });

    _socket!.on('error', (data) {
      debugPrint('[Socket] Error: $data');
    });

    // ── Listen for stream events ──────────────────────────────────

    _socket!.on('stream:chat-message', (data) {
      if (data is Map<String, dynamic>) {
        _chatController.add(LiveStreamChatMessage.fromJson(data));
      }
    });

    _socket!.on('stream:gift-received', (data) {
      if (data is Map<String, dynamic>) {
        _giftController.add(data);
        // Also add as a chat message
        _chatController.add(LiveStreamChatMessage(
          username: data['username'] ?? 'Someone',
          message: 'sent ${data['giftName'] ?? 'a gift'}!',
          type: 'gift',
          giftName: data['giftName'],
          giftValue: data['giftValue'],
          timestamp: DateTime.now(),
        ));
      }
    });

    _socket!.on('stream:viewer-joined', (data) {
      if (data is Map<String, dynamic>) {
        _viewerJoinedController.add(data);
        if (data['viewerCount'] != null) {
          _viewerCountController.add(data['viewerCount'] as int);
        }
      }
    });

    _socket!.on('stream:viewer-left', (data) {
      if (data is Map<String, dynamic>) {
        _viewerLeftController.add(data);
        if (data['viewerCount'] != null) {
          _viewerCountController.add(data['viewerCount'] as int);
        }
      }
    });

    _socket!.on('stream:ended', (data) {
      _streamEndedController.add(null);
    });

    _socket!.on('stream:reaction', (data) {
      if (data is Map<String, dynamic>) {
        _reactionController.add(data);
      }
    });

    _socket!.on('stream:state', (data) {
      if (data is Map<String, dynamic> && data['viewerCount'] != null) {
        _viewerCountController.add(data['viewerCount'] as int);
      }
    });

    _socket!.connect();
  }

  /// Disconnect from the Socket.io server.
  void disconnect() {
    if (_currentStreamId != null) {
      leaveStream(_currentStreamId!);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Join a stream room.
  void joinStream(String streamId) {
    if (_currentStreamId != null && _currentStreamId != streamId) {
      leaveStream(_currentStreamId!);
    }
    _currentStreamId = streamId;
    _socket?.emit('stream:join', {'streamId': streamId});
  }

  /// Leave a stream room.
  void leaveStream(String streamId) {
    _socket?.emit('stream:leave', {'streamId': streamId});
    if (_currentStreamId == streamId) {
      _currentStreamId = null;
    }
  }

  /// Send a chat message to the current stream.
  void sendChat(String streamId, String message) {
    _socket?.emit('stream:chat', {
      'streamId': streamId,
      'message': message,
    });
  }

  /// Send a gift to the stream.
  void sendGift(String streamId, String giftId, String giftName, int giftValue) {
    _socket?.emit('stream:gift', {
      'streamId': streamId,
      'giftId': giftId,
      'giftName': giftName,
      'giftValue': giftValue,
    });
  }

  /// Send a reaction to the stream.
  void sendReaction(String streamId, String reaction) {
    _socket?.emit('stream:reaction', {
      'streamId': streamId,
      'reaction': reaction,
    });
  }

  /// Send typing indicator.
  void sendTyping(String streamId) {
    _socket?.emit('stream:typing', {'streamId': streamId});
  }

  /// Raise hand to speak.
  void raiseHand(String streamId) {
    _socket?.emit('stream:raise-hand', {'streamId': streamId});
  }

  /// Dispose all stream controllers.
  void dispose() {
    disconnect();
    _chatController.close();
    _giftController.close();
    _viewerJoinedController.close();
    _viewerLeftController.close();
    _viewerCountController.close();
    _streamEndedController.close();
    _reactionController.close();
    _instance = null;
  }
}
