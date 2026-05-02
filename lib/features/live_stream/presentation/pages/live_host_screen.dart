import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/models/live_stream_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../data/services/socket_service.dart';
import '../widgets/live_video_widget.dart';
import '../widgets/clash_artist_picker.dart';
import '../widgets/clash_video_widget.dart';
import '../widgets/battle_bar_widget.dart';
import '../../../../data/models/live_clash_model.dart';
import '../pages/tiktok_live_page.dart';

/// The broadcasting dashboard for the artist.
class LiveHostScreen extends StatefulWidget {
  final String streamId;

  const LiveHostScreen({Key? key, required this.streamId}) : super(key: key);

  @override
  State<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends State<LiveHostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _liveIndicatorController;
  final TextEditingController _messageController = TextEditingController();

  late LiveStreamService _liveStreamService;
  late SocketService _socketService;

  LiveStreamModel? _stream;
  LiveStreamTokenData? _tokenData;
  List<LiveStreamChatMessage> _messages = [];
  int _viewerCount = 0;
  bool _isLoading = true;
  String? _error;
  LiveClashModel? _activeClash;

  StreamSubscription? _chatSub;
  StreamSubscription? _viewerCountSub;
  StreamSubscription? _clashStartedSub;
  StreamSubscription? _clashEndedSub;
  StreamSubscription? _clashScoreSub;
  StreamSubscription? _clashInvitationSub;

  @override
  void initState() {
    super.initState();
    _liveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  Future<void> _initServices() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final tokenStorage = Provider.of<TokenStorage>(context, listen: false);

    _liveStreamService = LiveStreamService(apiClient: apiClient);
    _socketService = SocketService.getInstance(tokenStorage: tokenStorage);

    await _socketService.connect();
    _setupSocketListeners();
    await _loadStream();
  }

  void _setupSocketListeners() {
    _chatSub = _socketService.onChatMessage.listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
          if (_messages.length > 200) {
            _messages = _messages.sublist(_messages.length - 200);
          }
        });
      }
    });

    _viewerCountSub = _socketService.onViewerCountChanged.listen((count) {
      if (mounted) setState(() => _viewerCount = count);
    });

    _clashStartedSub = _socketService.onClashStarted.listen((data) {
      if (mounted) {
        setState(() => _activeClash = LiveClashModel.fromJson(data));
      }
    });

    _clashEndedSub = _socketService.onClashEnded.listen((data) {
      if (mounted) {
        setState(() => _activeClash = null);
        final winnerId = data['winnerId'];
        final winnerName = data['winnerName'] ?? 'Someone';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clash Ended! Winner: $winnerName', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    });

    _clashInvitationSub = _socketService.onClashInvitation.listen((data) {
      if (mounted) _showClashInvitationDialog(data);
    });

    _clashScoreSub = _socketService.onClashScoreUpdate.listen((data) {
      if (mounted && _activeClash != null) {
        setState(() {
          _activeClash = LiveClashModel(
            id: _activeClash!.id,
            challenger: _activeClash!.challenger,
            opponent: _activeClash!.opponent,
            status: _activeClash!.status,
            duration: _activeClash!.duration,
            startTime: _activeClash!.startTime,
            challengerScore: (data['challengerScore'] ?? 0).toDouble(),
            opponentScore: (data['opponentScore'] ?? 0).toDouble(),
          );
        });
      }
    });
  }

  Future<void> _loadStream() async {
    try {
      final results = await Future.wait([
        _liveStreamService.getStream(widget.streamId),
        _liveStreamService.getStreamToken(widget.streamId),
      ]);

      final stream = results[0] as LiveStreamModel;
      final tokenData = results[1] as LiveStreamTokenData;

      _socketService.joinStream(widget.streamId);

      if (mounted) {
        setState(() {
          _stream = stream;
          _tokenData = tokenData;
          _viewerCount = stream.currentViewers;
          _messages = List.from(stream.chatMessages);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeumorphicTheme.backgroundColor,
        title: const Text('End Live Stream?', style: TextStyle(color: NeumorphicTheme.textPrimary)),
        content: const Text('Are you sure you want to end your stream?', style: TextStyle(color: NeumorphicTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('END LIVE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _liveStreamService.endStream(widget.streamId);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to end stream: $e')),
          );
        }
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _socketService.sendChat(widget.streamId, _messageController.text.trim());
    _messageController.clear();
  }

  void _showClashPicker() async {
    final opponentId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClashArtistPicker(currentStreamId: widget.streamId),
    );

    if (opponentId != null) {
      try {
        await _liveStreamService.inviteToClash(opponentId, 300); // 5 mins
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Battle invitation sent! 🔥')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to invite: $e')),
          );
        }
      }
    }
  }

  void _showClashInvitationDialog(Map<String, dynamic> data) {
    final challengerName = data['challengerName'] ?? 'An Artist';
    final clashId = data['clashId'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: NeumorphicTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔥 BATTLE CHALLENGE!', 
          style: TextStyle(color: NeumorphicTheme.primaryAccent, fontWeight: FontWeight.bold)),
        content: Text('$challengerName wants to clash! Ready to prove your skills?', 
          style: const TextStyle(color: NeumorphicTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              _liveStreamService.rejectClash(clashId);
              Navigator.pop(context);
            },
            child: const Text('REJECT', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _liveStreamService.acceptClash(clashId);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _viewerCountSub?.cancel();
    _clashStartedSub?.cancel();
    _clashEndedSub?.cancel();
    _clashScoreSub?.cancel();
    _clashInvitationSub?.cancel();
    _socketService.leaveStream(widget.streamId);
    _messageController.dispose();
    _liveIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endStream();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Broadcaster video
            Positioned.fill(
              child: (_activeClash != null && _tokenData != null)
                  ? ClashVideoWidget(
                      tokenData: _tokenData!,
                      challengerId: _activeClash!.challenger.id,
                      opponentId: _activeClash!.opponent.id,
                      isHost: true,
                    )
                  : (_tokenData != null
                      ? LiveVideoWidget(
                          tokenData: _tokenData!,
                          isHost: true,
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white))),
            ),

            // Battle Bar (if active)
            if (_activeClash != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: BattleBarWidget(
                    challengerScore: _activeClash!.challengerScore,
                    opponentScore: _activeClash!.opponentScore,
                    challengerName: _activeClash!.challenger.name,
                    opponentName: _activeClash!.opponent.name,
                    durationSeconds: _activeClash!.duration,
                    startTime: _activeClash!.startTime,
                  ),
                ),
              ),

            // Top Overlay (Stats, End Button)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Indicator & Viewer Count
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _liveIndicatorController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8 + (_liveIndicatorController.value * 0.2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('$_viewerCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // End Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _endStream,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('END LIVE'),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Overlay (Chat)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Chat messages
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${msg.username}: ', 
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                                Expanded(
                                  child: Text(msg.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Input field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Chat with your fans...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF10B981)),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Clash Trigger Button
            if (_activeClash == null && !_isLoading)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showClashPicker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.bolt, color: Colors.redAccent, size: 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('CLASH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
