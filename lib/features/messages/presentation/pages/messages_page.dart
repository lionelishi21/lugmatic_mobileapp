import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/providers/message_provider.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../../core/config/api_config.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Visit an artist profile to start a chat', 
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchConversations,
            color: const Color(0xFF10B981),
            child: ListView.builder(
              itemCount: provider.conversations.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final lastMsg = conversation.lastMessage?['content'] ?? 'No messages yet';
    final timestamp = conversation.updatedAt;
    final timeStr = DateFormat.jm().format(timestamp);
    final profilePic = ApiConfig.resolveUrl(conversation.otherParticipantProfilePicture);

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
            child: profilePic.isEmpty ? Text(conversation.otherParticipantName[0], 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
          ),
          if (conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: Text('${conversation.unreadCount}', 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(conversation.otherParticipantName, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          lastMsg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.unreadCount > 0 ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.4),
            fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
