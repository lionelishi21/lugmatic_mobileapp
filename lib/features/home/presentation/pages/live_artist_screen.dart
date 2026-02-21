import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/models/live_stream_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../data/services/socket_service.dart';
import '../../../live_stream/presentation/widgets/live_video_widget.dart';

/// Chat-focused live stream page.
///
/// Accepts a [streamId] to fetch details from the API,
/// connects to LiveKit for video and Socket.io for chat.
class LiveArtistScreen extends StatefulWidget {
  final String streamId;

  const LiveArtistScreen({Key? key, required this.streamId}) : super(key: key);

  @override
  State<LiveArtistScreen> createState() => _LiveArtistScreenState();
}

class _LiveArtistScreenState extends State<LiveArtistScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late AnimationController _liveIndicatorController;

  late LiveStreamService _liveStreamService;
  late SocketService _socketService;

  LiveStreamModel? _stream;
  LiveStreamTokenData? _tokenData;
  List<LiveStreamChatMessage> _messages = [];
  int _viewerCount = 0;
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _chatSub;
  StreamSubscription? _viewerCountSub;
  StreamSubscription? _streamEndedSub;

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

    _streamEndedSub = _socketService.onStreamEnded.listen((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stream has ended')),
        );
        Navigator.pop(context);
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

  @override
  void dispose() {
    _chatSub?.cancel();
    _viewerCountSub?.cancel();
    _streamEndedSub?.cancel();
    _socketService.leaveStream(widget.streamId);
    _messageController.dispose();
    _liveIndicatorController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _socketService.sendChat(widget.streamId, _messageController.text.trim());
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeumorphicTheme.backgroundColor,
              NeumorphicTheme.surfaceColor,
              NeumorphicTheme.backgroundColor,
            ],
          ),
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeumorphicTheme.backgroundColor,
              NeumorphicTheme.surfaceColor,
              NeumorphicTheme.backgroundColor,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeumorphicTheme.backgroundColor,
            NeumorphicTheme.surfaceColor,
            NeumorphicTheme.backgroundColor,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: NeumorphicButton(
            width: 50,
            height: 50,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(15),
            onPressed: () => Navigator.pop(context),
            child:
                const Icon(Icons.close, color: NeumorphicTheme.textPrimary),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Indicator
              AnimatedBuilder(
                animation: _liveIndicatorController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(
                          0.8 + (_liveIndicatorController.value * 0.2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                _stream?.host?.name ?? 'Live Stream',
                style: const TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: NeumorphicCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye,
                      color: NeumorphicTheme.primaryAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_viewerCount',
                      style: const TextStyle(
                        color: NeumorphicTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Video / Performance Area
            Expanded(
              flex: 2,
              child: NeumorphicContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                borderRadius: BorderRadius.circular(30),
                color: NeumorphicTheme.surfaceColor,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: _tokenData != null
                      ? LiveVideoWidget(
                          tokenData: _tokenData!,
                          isHost: _tokenData!.isHost,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NeumorphicTheme.accentGradientStart
                                    .withOpacity(0.3),
                                NeumorphicTheme.accentGradientEnd
                                    .withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        ),
                ),
              ),
            ),

            // Chat Area
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble,
                          color: NeumorphicTheme.primaryAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Chat',
                          style: TextStyle(
                            color: NeumorphicTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_viewerCount watching',
                          style: TextStyle(
                            color: NeumorphicTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Messages List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMessage(message),
                        );
                      },
                    ),
                  ),

                  // Message Input
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: NeumorphicContainer(
                            isConcave: true,
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(25),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(
                                  color: NeumorphicTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: "Send a message...",
                                hintStyle: TextStyle(
                                  color: NeumorphicTheme.textTertiary
                                      .withOpacity(0.5),
                                ),
                                filled: true,
                                fillColor: NeumorphicTheme.backgroundColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeumorphicButton(
                          width: 56,
                          height: 56,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(28),
                          isGradient: true,
                          gradientColors: [
                            NeumorphicTheme.accentGradientStart,
                            NeumorphicTheme.accentGradientEnd,
                          ],
                          onPressed: _sendMessage,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(LiveStreamChatMessage message) {
    final isArtist =
        message.userId == _stream?.hostUserId;

    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      color: isArtist
          ? NeumorphicTheme.cardColor.withOpacity(0.8)
          : (message.isGift
              ? const Color(0xFFFFD700).withOpacity(0.15)
              : NeumorphicTheme.surfaceColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isArtist
                      ? LinearGradient(
                          colors: [
                            NeumorphicTheme.accentGradientStart,
                            NeumorphicTheme.accentGradientEnd,
                          ],
                        )
                      : null,
                  color: isArtist
                      ? null
                      : (message.isGift
                          ? const Color(0xFFFFD700)
                          : NeumorphicTheme.backgroundColor),
                ),
                child: Icon(
                  isArtist
                      ? Icons.star
                      : (message.isGift
                          ? Icons.card_giftcard
                          : Icons.person),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.username,
                style: TextStyle(
                  color: isArtist
                      ? NeumorphicTheme.primaryAccent
                      : NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isArtist) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  color: NeumorphicTheme.primaryAccent,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.isGift
                ? '${message.message} (${message.giftValue ?? 0} coins)'
                : message.message,
            style: const TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
