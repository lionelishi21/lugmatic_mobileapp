import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/providers/message_provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../data/services/socket_service.dart';

class ChatPage extends StatefulWidget {
  final ConversationModel conversation;
  const ChatPage({Key? key, required this.conversation}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService _socketService;
  StreamSubscription? _typingSub;
  StreamSubscription? _stopTypingSub;
  Timer? _stopTypingTimer;
  bool _otherIsTyping = false;

  String get _recipientId => widget.conversation.otherParticipant['_id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchMessages(widget.conversation.id);
    });
    _socketService = SocketService.getInstance(tokenStorage: context.read<TokenStorage>());
    _typingSub = _socketService.onDmTyping.listen((data) {
      if (data['conversationId'] == widget.conversation.id && mounted) {
        setState(() => _otherIsTyping = true);
      }
    });
    _stopTypingSub = _socketService.onDmStopTyping.listen((data) {
      if (data['conversationId'] == widget.conversation.id && mounted) {
        setState(() => _otherIsTyping = false);
      }
    });
    _controller.addListener(_onTyping);
  }

  void _onTyping() {
    if (_recipientId.isEmpty) return;
    _socketService.sendDmTyping(recipientId: _recipientId, conversationId: widget.conversation.id);
    _stopTypingTimer?.cancel();
    _stopTypingTimer = Timer(const Duration(seconds: 2), () {
      _socketService.sendDmStopTyping(recipientId: _recipientId, conversationId: widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTyping);
    _typingSub?.cancel();
    _stopTypingSub?.cancel();
    _stopTypingTimer?.cancel();
    if (_recipientId.isNotEmpty) {
      _socketService.sendDmStopTyping(recipientId: _recipientId, conversationId: widget.conversation.id);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    _stopTypingTimer?.cancel();
    if (_recipientId.isNotEmpty) {
      _socketService.sendDmStopTyping(recipientId: _recipientId, conversationId: widget.conversation.id);
    }
    try {
      await context.read<MessageProvider>().sendMessage(widget.conversation.id, content);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    final profilePic = ApiConfig.resolveUrl(widget.conversation.otherParticipantProfilePicture);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty ? Text(widget.conversation.otherParticipantName[0], 
                style: const TextStyle(fontSize: 12, color: Colors.white)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.conversation.otherParticipantName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_otherIsTyping)
                    const Text('typing…',
                        style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessagesForConversation(widget.conversation.id);
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final fromMe = msg.isFromMe(myId);
                    
                    return _MessageBubble(message: msg, fromMe: fromMe);
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool fromMe;

  const _MessageBubble({required this.message, required this.fromMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: fromMe ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: fromMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: fromMe ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: fromMe ? Colors.black : Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(message.createdAt),
              style: TextStyle(
                color: (fromMe ? Colors.black : Colors.white).withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
