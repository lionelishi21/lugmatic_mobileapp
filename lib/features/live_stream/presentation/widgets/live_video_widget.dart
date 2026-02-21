import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../data/models/live_stream_model.dart';

/// Widget that connects to a LiveKit room and renders the host's video.
///
/// Falls back to an audio-only visualization when no video track is available.
/// Exposes host controls (mic/camera toggle) when [isHost] is true.
class LiveVideoWidget extends StatefulWidget {
  final LiveStreamTokenData tokenData;
  final bool isHost;
  final VoidCallback? onDisconnected;

  const LiveVideoWidget({
    Key? key,
    required this.tokenData,
    this.isHost = false,
    this.onDisconnected,
  }) : super(key: key);

  @override
  State<LiveVideoWidget> createState() => _LiveVideoWidgetState();
}

class _LiveVideoWidgetState extends State<LiveVideoWidget>
    with SingleTickerProviderStateMixin {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _error;
  VideoTrack? _videoTrack;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    try {
      _room = Room();
      _listener = _room!.createListener();

      // Listen for track events
      _listener!
        ..on<TrackSubscribedEvent>((event) {
          _updateVideoTrack();
        })
        ..on<TrackUnsubscribedEvent>((event) {
          _updateVideoTrack();
        })
        ..on<LocalTrackPublishedEvent>((event) {
          _updateVideoTrack();
        })
        ..on<LocalTrackUnpublishedEvent>((event) {
          _updateVideoTrack();
        })
        ..on<RoomDisconnectedEvent>((event) {
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
            widget.onDisconnected?.call();
          }
        });

      await _room!.connect(
        widget.tokenData.url,
        widget.tokenData.token,
      );

      // If host, enable mic/camera
      if (widget.isHost) {
        await _room!.localParticipant?.setCameraEnabled(true);
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
        });
        _updateVideoTrack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _updateVideoTrack() {
    if (!mounted || _room == null) return;

    VideoTrack? track;

    // First, check remote participants for a video track (viewer mode)
    for (final participant in _room!.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.track != null && pub.subscribed == true) {
          track = pub.track as VideoTrack;
          break;
        }
      }
      if (track != null) break;
    }

    // If host, check local participant
    if (track == null && widget.isHost && _room!.localParticipant != null) {
      for (final pub in _room!.localParticipant!.videoTrackPublications) {
        if (pub.track != null) {
          track = pub.track as VideoTrack;
          break;
        }
      }
    }

    setState(() {
      _videoTrack = track;
    });
  }

  Future<void> _toggleMic() async {
    if (_room?.localParticipant == null) return;
    _isMicOn = !_isMicOn;
    await _room!.localParticipant!.setMicrophoneEnabled(_isMicOn);
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_room?.localParticipant == null) return;
    _isCameraOn = !_isCameraOn;
    await _room!.localParticipant!.setCameraEnabled(_isCameraOn);
    setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isConnecting) {
      return _buildConnectingState();
    }

    return Stack(
      children: [
        // Video or audio-only visualization
        if (_videoTrack != null)
          VideoTrackRenderer(
            _videoTrack!,
            fit: VideoViewFit.cover,
            mirrorMode: widget.isHost
                ? VideoViewMirrorMode.mirror
                : VideoViewMirrorMode.off,
          )
        else
          _buildAudioOnlyState(),

        // Host controls overlay
        if (widget.isHost && _isConnected)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMicOn ? Icons.mic : Icons.mic_off,
                  isActive: _isMicOn,
                  onTap: _toggleMic,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  isActive: _isCameraOn,
                  onTap: _toggleCamera,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildConnectingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Joining stream...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioOnlyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.8),
            Colors.blue.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_pulseController.value * 0.2),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headphones,
                      size: 50,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Audio-Only Stream',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected ? 'Connected' : 'Connecting...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to connect',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Unknown error',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
