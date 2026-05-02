class ConversationModel {
  final String id;
  final Map<String, dynamic> otherParticipant;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.otherParticipant,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] ?? '',
      otherParticipant: json['otherParticipant'] ?? {},
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get otherParticipantName {
    final first = otherParticipant['firstName'] ?? '';
    final last = otherParticipant['lastName'] ?? '';
    return '$first $last'.trim().isEmpty ? 'Unknown' : '$first $last'.trim();
  }

  String get otherParticipantProfilePicture => otherParticipant['profilePicture'] ?? '';
}
