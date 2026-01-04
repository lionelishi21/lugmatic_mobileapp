import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/models/artist_model.dart';

class LiveArtistScreen extends StatefulWidget {
  final ArtistModel artist;

  const LiveArtistScreen({Key? key, required this.artist}) : super(key: key);

  @override
  State<LiveArtistScreen> createState() => _LiveArtistScreenState();
}

class _LiveArtistScreenState extends State<LiveArtistScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late AnimationController _liveIndicatorController;
  int _viewerCount = 1247;

  @override
  void initState() {
    super.initState();
    _liveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Add some dummy messages
    _addDummyMessages();
  }

  void _addDummyMessages() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            username: widget.artist.name,
            message: "Hey everyone! Thanks for joining the live session! 🎵",
            isArtist: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            username: "MusicLover23",
            message: "This is amazing! Love your music!",
            isArtist: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            username: "SoundWave99",
            message: "Can you play Midnight Dreams next?",
            isArtist: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            username: widget.artist.name,
            message: "Of course! Here it comes! 🎸",
            isArtist: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _liveIndicatorController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        username: "You",
        message: _messageController.text,
        isArtist: false,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });

    // Simulate artist response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            username: widget.artist.name,
            message: "Thanks for your message! Love having you here! ❤️",
            isArtist: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.close, color: NeumorphicTheme.textPrimary),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Indicator
              AnimatedBuilder(
                animation: _liveIndicatorController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8 + (_liveIndicatorController.value * 0.2)),
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
                widget.artist.name,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            // Video/Performance Area
            Expanded(
              flex: 2,
              child: NeumorphicContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(30),
                color: NeumorphicTheme.surfaceColor,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NeumorphicTheme.accentGradientStart.withOpacity(0.3),
                        NeumorphicTheme.accentGradientEnd.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              NeumorphicTheme.accentGradientStart,
                              NeumorphicTheme.accentGradientEnd,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '🎵 Live Performance 🎵',
                        style: TextStyle(
                          color: NeumorphicTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Playing: Midnight Dreams',
                        style: TextStyle(
                          color: NeumorphicTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                        Text(
                          'Live Chat',
                          style: TextStyle(
                            color: NeumorphicTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                              style: const TextStyle(color: NeumorphicTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: "Send a message...",
                                hintStyle: TextStyle(
                                  color: NeumorphicTheme.textTertiary.withOpacity(0.5),
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

  Widget _buildMessage(ChatMessage message) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      color: message.isArtist
          ? NeumorphicTheme.cardColor.withOpacity(0.8)
          : NeumorphicTheme.surfaceColor,
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
                  gradient: message.isArtist
                      ? LinearGradient(
                          colors: [
                            NeumorphicTheme.accentGradientStart,
                            NeumorphicTheme.accentGradientEnd,
                          ],
                        )
                      : null,
                  color: message.isArtist ? null : NeumorphicTheme.backgroundColor,
                ),
                child: Icon(
                  message.isArtist ? Icons.star : Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.username,
                style: TextStyle(
                  color: message.isArtist
                      ? NeumorphicTheme.primaryAccent
                      : NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (message.isArtist) ...[
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
            message.message,
            style: TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String username;
  final String message;
  final bool isArtist;
  final DateTime timestamp;

  ChatMessage({
    required this.username,
    required this.message,
    required this.isArtist,
    required this.timestamp,
  });
}

