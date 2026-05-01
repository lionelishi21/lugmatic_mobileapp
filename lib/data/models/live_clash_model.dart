import 'package:lugmatic_flutter/data/models/live_stream_model.dart';

class LiveClashModel {
  final String id;
  final LiveStreamHost challenger;
  final LiveStreamHost opponent;
  final String status; // pending, active, ended, cancelled, rejected
  final int duration;
  final double challengerScore;
  final double opponentScore;
  final String? winnerId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String realm;
  final String? clashRoomName;
  final String? livekitUrl;
  final String? challengerUserId;
  final String? opponentUserId;

  const LiveClashModel({
    required this.id,
    required this.challenger,
    required this.opponent,
    required this.status,
    required this.duration,
    this.challengerScore = 0,
    this.opponentScore = 0,
    this.winnerId,
    this.startTime,
    this.endTime,
    this.realm = 'fire',
    this.clashRoomName,
    this.livekitUrl,
    this.challengerUserId,
    this.opponentUserId,
  });

  factory LiveClashModel.fromJson(Map<String, dynamic> json) {
    return LiveClashModel(
      id: json['_id']?.toString() ?? json['clashId']?.toString() ?? json['id']?.toString() ?? '',
      challenger: json['challenger'] is Map
          ? LiveStreamHost.fromJson(json['challenger'])
          : LiveStreamHost(id: json['challenger']?.toString() ?? '', name: 'Challenger'),
      opponent: json['opponent'] is Map
          ? LiveStreamHost.fromJson(json['opponent'])
          : LiveStreamHost(id: json['opponent']?.toString() ?? '', name: 'Opponent'),
      status: json['status'] ?? 'pending',
      duration: json['duration'] ?? 300,
      challengerScore: (json['challengerScore'] ?? 0).toDouble(),
      opponentScore: (json['opponentScore'] ?? 0).toDouble(),
      winnerId: json['winner'] is String
          ? json['winner']
          : json['winner']?['_id']?.toString(),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      realm: json['realm'] ?? 'fire',
      clashRoomName: json['clashRoomName']?.toString(),
      livekitUrl: json['livekitUrl']?.toString(),
      challengerUserId: json['challengerUserId']?.toString(),
      opponentUserId: json['opponentUserId']?.toString(),
    );
  }

  LiveClashModel copyWith({
    double? challengerScore,
    double? opponentScore,
    String? realm,
    String? status,
  }) => LiveClashModel(
    id: id, challenger: challenger, opponent: opponent,
    status: status ?? this.status, duration: duration,
    challengerScore: challengerScore ?? this.challengerScore,
    opponentScore: opponentScore ?? this.opponentScore,
    winnerId: winnerId, startTime: startTime, endTime: endTime,
    realm: realm ?? this.realm,
    clashRoomName: clashRoomName, livekitUrl: livekitUrl,
    challengerUserId: challengerUserId, opponentUserId: opponentUserId,
  );

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
}
