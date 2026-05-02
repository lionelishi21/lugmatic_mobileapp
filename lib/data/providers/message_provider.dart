import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService;
  final SocketService _socketService;

  List<ConversationModel> _conversations = [];
  Map<String, List<MessageModel>> _messages = {};
  bool _loading = false;
  int _totalUnreadCount = 0;

  List<ConversationModel> get conversations => _conversations;
  int get totalUnreadCount => _totalUnreadCount;
  bool get isLoading => _loading;

  MessageProvider({
    required MessageService messageService,
    required SocketService socketService,
  })  : _messageService = messageService,
        _socketService = socketService {
    _initSocket();
  }

  void _initSocket() {
    _socketService.onDmMessage.listen((data) {
      // Refresh conversation list on new message to update last message and unread counts
      fetchConversations();
      
      // If we are currently in a chat, add the message to the list
      final conversationId = data['conversation']?.toString();
      if (conversationId != null && _messages.containsKey(conversationId)) {
        final newMessage = MessageModel.fromJson(data);
        
        // Avoid duplicates if we just sent it
        if (!_messages[conversationId]!.any((m) => m.id == newMessage.id)) {
          _messages[conversationId]!.insert(0, newMessage);
          notifyListeners();
        }
      }
    });
  }

  Future<void> fetchConversations() async {
    try {
      _conversations = await _messageService.getConversations();
      _totalUnreadCount = await _messageService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    }
  }

  Future<void> setInitialLoading(bool val) async {
    _loading = val;
    notifyListeners();
  }

  List<MessageModel> getMessagesForConversation(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final msgs = await _messageService.getMessages(conversationId);
      _messages[conversationId] = msgs;
      notifyListeners();
      
      // Mark as read
      await _messageService.markAsRead(conversationId);
      fetchConversations(); // refresh unread counts
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final msg = await _messageService.sendMessage(conversationId, content);
    if (_messages.containsKey(conversationId)) {
      // Check for duplicates before inserting
      if (!_messages[conversationId]!.any((m) => m.id == msg.id)) {
        _messages[conversationId]!.insert(0, msg);
        notifyListeners();
      }
    }
    fetchConversations(); // Update last message in list
    return msg;
  }

  Future<ConversationModel> startConversation(String artistId) async {
    return await _messageService.startConversation(artistId);
  }
}
