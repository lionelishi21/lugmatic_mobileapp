class RegularClashArtist {
  final String id;
  final String name;
  final String? image;

  const RegularClashArtist({required this.id, required this.name, this.image});

  factory RegularClashArtist.fromJson(Map<String, dynamic> json) {
    return RegularClashArtist(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      image: json['image']?.toString(),
    );
  }
}

class RegularClashVideo {
  final String? videoUrl;
  final String? videoKey;
  final String? thumbnailUrl;
  final int? duration;
  final DateTime? submittedAt;

  const RegularClashVideo({
    this.videoUrl,
    this.videoKey,
    this.thumbnailUrl,
    this.duration,
    this.submittedAt,
  });

  factory RegularClashVideo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegularClashVideo();
    return RegularClashVideo(
      videoUrl: json['videoUrl']?.toString(),
      videoKey: json['videoKey']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      duration: json['duration'] as int?,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt']) : null,
    );
  }

  bool get isSubmitted => submittedAt != null && videoUrl != null;
}

class RegularClashModel {
  final String id;
  final String? poolId;
  final RegularClashArtist challenger;
  final RegularClashArtist opponent;
  final String status; // pending | accepted | active | voting | ended | rejected
  final String realm;
  final RegularClashVideo? challengerVideo;
  final RegularClashVideo? opponentVideo;
  final int challengerVotes;
  final int opponentVotes;
  final int challengerGiftPoints;
  final int opponentGiftPoints;
  final int likesCount;
  final RegularClashArtist? winner;
  final String? message;
  final String? rhythmId;
  final DateTime createdAt;

  const RegularClashModel({
    required this.id,
    this.poolId,
    required this.challenger,
    required this.opponent,
    required this.status,
    this.realm = 'fire',
    this.challengerVideo,
    this.opponentVideo,
    this.challengerVotes = 0,
    this.opponentVotes = 0,
    this.challengerGiftPoints = 0,
    this.opponentGiftPoints = 0,
    this.likesCount = 0,
    this.winner,
    this.message,
    this.rhythmId,
    required this.createdAt,
  });

  factory RegularClashModel.fromJson(Map<String, dynamic> json) {
    final giftPoints = json['giftPoints'] as Map<String, dynamic>? ?? {};
    return RegularClashModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      poolId: json['pool'] is Map ? json['pool']['_id']?.toString() : json['pool']?.toString(),
      challenger: json['challenger'] is Map
          ? RegularClashArtist.fromJson(json['challenger'])
          : RegularClashArtist(id: json['challenger']?.toString() ?? '', name: 'Challenger'),
      opponent: json['opponent'] is Map
          ? RegularClashArtist.fromJson(json['opponent'])
          : RegularClashArtist(id: json['opponent']?.toString() ?? '', name: 'Opponent'),
      status: json['status'] ?? 'pending',
      realm: json['realm'] ?? 'fire',
      challengerVideo: json['challengerVideo'] is Map
          ? RegularClashVideo.fromJson(json['challengerVideo'])
          : null,
      opponentVideo: json['opponentVideo'] is Map
          ? RegularClashVideo.fromJson(json['opponentVideo'])
          : null,
      challengerVotes: (json['challengerVotes'] ?? 0) as int,
      opponentVotes: (json['opponentVotes'] ?? 0) as int,
      challengerGiftPoints: (giftPoints['challenger'] ?? 0) as int,
      opponentGiftPoints: (giftPoints['opponent'] ?? 0) as int,
      likesCount: (json['likesCount'] ?? 0) as int,
      winner: json['winner'] is Map ? RegularClashArtist.fromJson(json['winner']) : null,
      message: json['message']?.toString(),
      rhythmId: json['rhythm']?.toString() ?? json['rhythmId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isVoting => status == 'voting';
  bool get isEnded => status == 'ended';
  bool get bothVideosSubmitted =>
      (challengerVideo?.isSubmitted ?? false) && (opponentVideo?.isSubmitted ?? false);

  int get totalVotes => challengerVotes + opponentVotes;
  double get challengerVotePercent =>
      totalVotes == 0 ? 0.5 : challengerVotes / totalVotes;
}
