/// Model for live stream data returned by the backend API.
class LiveStreamModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String coverImage;
  final LiveStreamHost? host;
  final String? hostUserId;
  final String livekitRoom;
  final String status;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? endTime;
  final int duration;
  final int currentViewers;
  final int peakViewers;
  final int totalViewers;
  final List<LiveStreamSpeaker> speakers;
  final List<LiveStreamChatMessage> chatMessages;
  final int totalGiftsReceived;
  final int totalGiftValue;
  final bool chatEnabled;
  final bool giftsEnabled;
  final List<String> tags;
  final DateTime? createdAt;

  const LiveStreamModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'music',
    this.coverImage = '',
    this.host,
    this.hostUserId,
    this.livekitRoom = '',
    this.status = 'scheduled',
    this.scheduledStartTime,
    this.actualStartTime,
    this.endTime,
    this.duration = 0,
    this.currentViewers = 0,
    this.peakViewers = 0,
    this.totalViewers = 0,
    this.speakers = const [],
    this.chatMessages = const [],
    this.totalGiftsReceived = 0,
    this.totalGiftValue = 0,
    this.chatEnabled = true,
    this.giftsEnabled = true,
    this.tags = const [],
    this.createdAt,
  });

  bool get isLive => status == 'live';

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'music',
      coverImage: json['coverImage'] ?? '',
      host: json['host'] != null
          ? (json['host'] is Map
              ? LiveStreamHost.fromJson(json['host'])
              : null)
          : null,
      hostUserId: json['hostUser'] is String
          ? json['hostUser']
          : json['hostUser']?['_id']?.toString(),
      livekitRoom: json['livekitRoom'] ?? '',
      status: json['status'] ?? 'scheduled',
      scheduledStartTime: json['scheduledStartTime'] != null
          ? DateTime.tryParse(json['scheduledStartTime'])
          : null,
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.tryParse(json['actualStartTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'])
          : null,
      duration: json['duration'] ?? 0,
      currentViewers: json['currentViewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? 0,
      totalViewers: json['totalViewers'] ?? 0,
      speakers: (json['speakers'] as List?)
              ?.map((s) => LiveStreamSpeaker.fromJson(s))
              .toList() ??
          [],
      chatMessages: (json['chatMessages'] as List?)
              ?.map((m) => LiveStreamChatMessage.fromJson(m))
              .toList() ??
          [],
      totalGiftsReceived: json['totalGiftsReceived'] ?? 0,
      totalGiftValue: json['totalGiftValue'] ?? 0,
      chatEnabled: json['chatEnabled'] ?? true,
      giftsEnabled: json['giftsEnabled'] ?? true,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// Host artist info (populated from Artist model).
class LiveStreamHost {
  final String id;
  final String name;
  final String image;
  final List<String> genres;
  final bool verified;

  const LiveStreamHost({
    required this.id,
    required this.name,
    this.image = '',
    this.genres = const [],
    this.verified = false,
  });

  factory LiveStreamHost.fromJson(Map<String, dynamic> json) {
    return LiveStreamHost(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      genres:
          (json['genres'] as List?)?.map((g) => g.toString()).toList() ?? [],
      verified: json['isVerified'] ?? json['verified'] ?? false,
    );
  }
}

/// Speaker in a live stream.
class LiveStreamSpeaker {
  final String userId;
  final String role;
  final bool isMuted;
  final DateTime? joinedAt;

  const LiveStreamSpeaker({
    required this.userId,
    this.role = 'listener',
    this.isMuted = true,
    this.joinedAt,
  });

  factory LiveStreamSpeaker.fromJson(Map<String, dynamic> json) {
    return LiveStreamSpeaker(
      userId: json['user']?.toString() ?? '',
      role: json['role'] ?? 'listener',
      isMuted: json['isMuted'] ?? true,
      joinedAt:
          json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
    );
  }
}

/// Chat message in a live stream.
class LiveStreamChatMessage {
  final String? id;
  final String userId;
  final String username;
  final String profilePicture;
  final String message;
  final String type; // chat, gift, system, join, leave
  final String? giftName;
  final int? giftValue;
  final DateTime timestamp;

  const LiveStreamChatMessage({
    this.id,
    this.userId = '',
    required this.username,
    this.profilePicture = '',
    required this.message,
    this.type = 'chat',
    this.giftName,
    this.giftValue,
    required this.timestamp,
  });

  bool get isGift => type == 'gift';
  bool get isSystem => type == 'system' || type == 'join' || type == 'leave';

  factory LiveStreamChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveStreamChatMessage(
      id: json['_id']?.toString(),
      userId: json['user']?.toString() ?? '',
      username: json['username'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'chat',
      giftName: json['giftName'],
      giftValue: json['giftValue'],
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Token data returned from /live-stream/:id/token.
class LiveStreamTokenData {
  final String token;
  final String url;
  final String roomName;
  final String role; // host, viewer

  const LiveStreamTokenData({
    required this.token,
    required this.url,
    required this.roomName,
    required this.role,
  });

  bool get isHost => role == 'host';

  factory LiveStreamTokenData.fromJson(Map<String, dynamic> json) {
    return LiveStreamTokenData(
      token: json['token'] ?? '',
      url: json['url'] ?? '',
      roomName: json['roomName'] ?? '',
      role: json['role'] ?? 'viewer',
    );
  }
}
