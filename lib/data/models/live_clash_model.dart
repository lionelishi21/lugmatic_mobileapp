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
  });

  factory LiveClashModel.fromJson(Map<String, dynamic> json) {
    return LiveClashModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      challenger: LiveStreamHost.fromJson(json['challenger']),
      opponent: LiveStreamHost.fromJson(json['opponent']),
      status: json['status'] ?? 'pending',
      duration: json['duration'] ?? 300,
      challengerScore: (json['challengerScore'] ?? 0).toDouble(),
      opponentScore: (json['opponentScore'] ?? 0).toDouble(),
      winnerId: json['winner'] is String 
          ? json['winner'] 
          : json['winner']?['_id']?.toString(),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
}
