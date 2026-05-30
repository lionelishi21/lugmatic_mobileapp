class ClashPoolModel {
  final String id;
  final String title;
  final String? description;
  final int season;
  final String status; // open | submission | voting | ended
  final String realm;
  final DateTime challengeDeadline;
  final DateTime submissionDeadline;
  final DateTime votingDeadline;
  final int totalClashes;
  final DateTime createdAt;

  const ClashPoolModel({
    required this.id,
    required this.title,
    this.description,
    required this.season,
    required this.status,
    required this.realm,
    required this.challengeDeadline,
    required this.submissionDeadline,
    required this.votingDeadline,
    this.totalClashes = 0,
    required this.createdAt,
  });

  factory ClashPoolModel.fromJson(Map<String, dynamic> json) {
    return ClashPoolModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      season: (json['season'] ?? 1) as int,
      status: json['status'] ?? 'open',
      realm: json['realm'] ?? 'fire',
      challengeDeadline: DateTime.tryParse(json['challengeDeadline'] ?? '') ?? DateTime.now(),
      submissionDeadline: DateTime.tryParse(json['submissionDeadline'] ?? '') ?? DateTime.now(),
      votingDeadline: DateTime.tryParse(json['votingDeadline'] ?? '') ?? DateTime.now(),
      totalClashes: (json['totalClashes'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isOpen => status == 'open';
  bool get isSubmission => status == 'submission';
  bool get isVoting => status == 'voting';
  bool get isEnded => status == 'ended';

  String get statusLabel {
    switch (status) {
      case 'open': return 'Challenge Period';
      case 'submission': return 'Video Submission';
      case 'voting': return 'Fan Voting';
      case 'ended': return 'Ended';
      default: return status.toUpperCase();
    }
  }
}
