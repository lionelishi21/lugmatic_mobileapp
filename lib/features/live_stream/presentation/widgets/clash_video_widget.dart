import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../data/models/live_stream_model.dart';

/// A specialized widget for rendering a 1v1 clash split-screen.
///
/// Connects to a LiveKit room and renders two video tracks side-by-side or top-bottom.
class ClashVideoWidget extends StatefulWidget {
  final LiveStreamTokenData tokenData;
  final String challengerId;
  final String opponentId;
  final bool isHost;

  const ClashVideoWidget({
    Key? key,
    required this.tokenData,
    required this.challengerId,
    required this.opponentId,
    this.isHost = false,
  }) : super(key: key);

  @override
  State<ClashVideoWidget> createState() => _ClashVideoWidgetState();
}

class _ClashVideoWidgetState extends State<ClashVideoWidget> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnecting = true;
  VideoTrack? _challengerTrack;
  VideoTrack? _opponentTrack;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    try {
      _room = Room();
      _listener = _room!.createListener();

      _listener!
        ..on<TrackSubscribedEvent>((_) => _updateTracks())
        ..on<TrackUnsubscribedEvent>((_) => _updateTracks())
        ..on<LocalTrackPublishedEvent>((_) => _updateTracks())
        ..on<LocalTrackUnpublishedEvent>((_) => _updateTracks());

      await _room!.connect(
        widget.tokenData.url,
        widget.tokenData.token,
      );

      if (widget.isHost) {
        await _room!.localParticipant?.setCameraEnabled(true);
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      }

      if (mounted) {
        setState(() => _isConnecting = false);
        _updateTracks();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
      debugPrint('ClashVideoWidget Error: $e');
    }
  }

  void _updateTracks() {
    if (!mounted || _room == null) return;

    VideoTrack? challenger;
    VideoTrack? opponent;

    // Check all participants (local and remote)
    final allParticipants = [
      if (_room!.localParticipant != null) _room!.localParticipant!,
      ..._room!.remoteParticipants.values,
    ];

    for (final participant in allParticipants) {
      // identify participant by metadata or identity
      // For now, let's assume identity matches the artist ID passed in
      final identity = participant is LocalParticipant 
          ? participant.identity 
          : (participant is RemoteParticipant ? participant.identity : '');
      
      VideoTrack? track;
      final pubs = participant is LocalParticipant 
          ? participant.videoTrackPublications 
          : (participant is RemoteParticipant ? participant.videoTrackPublications : []);
          
      for (final pub in pubs) {
        if (pub.track != null && pub.track is VideoTrack) {
          track = pub.track as VideoTrack;
          break;
        }
      }

      if (identity == widget.challengerId) {
        challenger = track;
      } else if (identity == widget.opponentId) {
        opponent = track;
      } else {
        // Fallback: if identities don't match exactly (e.g. prefixed), 
        // we might need more logic. For LUX, we'll try to find any 2 tracks if null.
      }
    }

    // Fallback logic if identities don't match (Viewer mode)
    if (challenger == null && opponent == null) {
      int count = 0;
      for (final participant in allParticipants) {
      final pubs = participant is LocalParticipant 
          ? participant.videoTrackPublications 
          : (participant is RemoteParticipant ? participant.videoTrackPublications : []);
          
      for (final pub in pubs) {
        if (pub.track != null && pub.track is VideoTrack) {
          if (count == 0) challenger = pub.track as VideoTrack;
          else if (count == 1) opponent = pub.track as VideoTrack;
          count++;
        }
      }
      }
    }

    setState(() {
      _challengerTrack = challenger;
      _opponentTrack = opponent;
    });
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Column(
      children: [
        // Top half: Challenger
        Expanded(
          child: Container(
            color: Colors.black,
            child: _challengerTrack != null
                ? VideoTrackRenderer(_challengerTrack!, fit: VideoViewFit.cover)
                : _buildPlaceholder('Challenger'),
          ),
        ),
        // Divider line or gap
        Container(height: 2, color: Colors.white24),
        // Bottom half: Opponent
        Expanded(
          child: Container(
            color: Colors.black,
            child: _opponentTrack != null
                ? VideoTrackRenderer(_opponentTrack!, fit: VideoViewFit.cover)
                : _buildPlaceholder('Opponent'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: Colors.white24, size: 64),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
