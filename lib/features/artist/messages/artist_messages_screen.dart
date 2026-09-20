import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/message_provider.dart';
import '../../messages/presentation/pages/chat_page.dart';

class ArtistMessagesScreen extends StatefulWidget {
  const ArtistMessagesScreen({super.key});

  @override
  State<ArtistMessagesScreen> createState() => _ArtistMessagesScreenState();
}

class _ArtistMessagesScreenState extends State<ArtistMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchConversations();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search conversations…',
            hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<MessageProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final filtered = _query.isEmpty
            ? provider.conversations
            : provider.conversations
                .where((c) => c.otherParticipantName.toLowerCase().contains(_query))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined, size: 72, color: AppColors.mutedForeground.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                const Text('No messages yet.',
                    style: TextStyle(
                        color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Fans who message you will appear here.',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchConversations,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildConversationTile(filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildConversationTile(ConversationModel conv) {
    final hasUnread = conv.unreadCount > 0;
    final lastText = conv.lastMessage?['content']?.toString() ?? '';
    final lastTime = conv.lastMessage?['createdAt'] != null
        ? DateTime.tryParse(conv.lastMessage!['createdAt'].toString()) ?? conv.updatedAt
        : conv.updatedAt;
    final profilePic = ApiConfig.resolveUrl(conv.otherParticipantProfilePicture);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty
                  ? Text(
                      conv.otherParticipantName.isNotEmpty ? conv.otherParticipantName[0] : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherParticipantName,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastText.isEmpty ? 'No messages yet' : lastText,
                    style: TextStyle(
                      color: hasUnread
                          ? AppColors.foreground.withValues(alpha: 0.8)
                          : AppColors.mutedForeground,
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(lastTime),
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                      style: const TextStyle(
                          color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.jm().format(dt);
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}
