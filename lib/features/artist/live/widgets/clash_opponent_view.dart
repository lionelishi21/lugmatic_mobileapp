import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class ClashOpponentView extends StatefulWidget {
  final String clashRoomUrl;
  final String clashRoomToken;
  final String opponentUserId;
  final String opponentName;
  final LocalVideoTrack? localVideoTrack;
  final LocalAudioTrack? localAudioTrack;

  const ClashOpponentView({
    super.key,
    required this.clashRoomUrl,
    required this.clashRoomToken,
    required this.opponentUserId,
    required this.opponentName,
    this.localVideoTrack,
    this.localAudioTrack,
  });

  @override
  State<ClashOpponentView> createState() => _ClashOpponentViewState();
}

class _ClashOpponentViewState extends State<ClashOpponentView> {
  Room? _room;
  VideoTrack? _opponentTrack;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      _room = Room();
      final listener = _room!.createListener();
      listener
        ..on<TrackSubscribedEvent>((_) => _findOpponentTrack())
        ..on<TrackUnsubscribedEvent>((_) => _findOpponentTrack())
        ..on<ParticipantConnectedEvent>((_) => _findOpponentTrack());

      await _room!.connect(widget.clashRoomUrl, widget.clashRoomToken);
      
      // Publish the existing tracks instead of re-capturing camera
      if (widget.localVideoTrack != null) {
        await _room!.localParticipant?.publishVideoTrack(widget.localVideoTrack!);
      }
      if (widget.localAudioTrack != null) {
        await _room!.localParticipant?.publishAudioTrack(widget.localAudioTrack!);
      }

      if (mounted) setState(() => _connecting = false);
      _findOpponentTrack();
    } catch (e) {
      debugPrint('ClashOpponentView connect error: $e');
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _findOpponentTrack() {
    if (!mounted || _room == null) return;
    VideoTrack? found;
    for (final p in _room!.remoteParticipants.values) {
      if (p.identity == widget.opponentUserId || found == null) {
        for (final pub in p.videoTrackPublications) {
          if (pub.track != null) {
            found = pub.track as VideoTrack?;
            if (p.identity == widget.opponentUserId) break;
          }
        }
        if (p.identity == widget.opponentUserId && found != null) break;
      }
    }
    
    // Fallback: Just grab the first remote video track if identity matching fails
    if (found == null) {
      for (final p in _room!.remoteParticipants.values) {
        for (final pub in p.videoTrackPublications) {
          if (pub.track != null) {
            found = pub.track as VideoTrack?;
            break;
          }
        }
        if (found != null) break;
      }
    }

    if (mounted) setState(() => _opponentTrack = found);
  }

  @override
  void dispose() {
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white54),
              SizedBox(height: 8),
              Text('Connecting opponent...', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_opponentTrack != null)
            VideoTrackRenderer(_opponentTrack!, fit: VideoViewFit.cover)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, color: Colors.white24, size: 48),
                  const SizedBox(height: 8),
                  Text(widget.opponentName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const Text('Connecting...', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text(widget.opponentName,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
