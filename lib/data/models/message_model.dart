class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      conversationId: json['conversation'] ?? '',
      senderId: json['sender'] is Map ? (json['sender']['_id'] ?? '') : (json['sender'] ?? ''),
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      sender: json['sender'] is Map ? json['sender'] : null,
    );
  }

  bool isFromMe(String myUserId) => senderId == myUserId;
}
