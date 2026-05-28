class Track {
  final String id;
  final String name;
  final String? coverArt;
  final String? coverArtUrl;
  final String status;
  final int playCount;
  final String? uploadSource;
  final DateTime createdAt;
  final double? share;
  final String? role;
  final String? videoUrl;

  Track({
    required this.id,
    required this.name,
    this.coverArt,
    this.coverArtUrl,
    required this.status,
    required this.playCount,
    this.uploadSource,
    required this.createdAt,
    this.share,
    this.role,
    this.videoUrl,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['_id'] ?? '',
        name: json['title'] ?? json['name'] ?? 'Unknown Track',
        coverArt: json['coverArt'] ?? json['coverImage'],
        coverArtUrl: json['coverArtUrl'],
        status: json['status'] ?? 'pending',
        playCount: json['plays'] ?? json['playCount'] ?? 0,
        uploadSource: json['uploadSource'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        share: json['share'] != null ? (json['share'] as num).toDouble() : null,
        role: json['role'],
        videoUrl: json['videoUrl'] as String?,
      );
}

class DailyStat {
  final String date;
  final int plays;

  DailyStat({required this.date, required this.plays});

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      DailyStat(date: json['date'] ?? '', plays: json['plays'] ?? 0);
}

class DeviceStat {
  final String device;
  final int count;

  DeviceStat({required this.device, required this.count});

  factory DeviceStat.fromJson(Map<String, dynamic> json) =>
      DeviceStat(device: json['device'] ?? 'Unknown', count: json['count'] ?? 0);
}

class TrackAnalytics {
  final int totalPlays;
  final List<DailyStat> dailyStats;
  final List<DeviceStat> deviceStats;
  final int period;

  TrackAnalytics({
    required this.totalPlays,
    required this.dailyStats,
    required this.deviceStats,
    required this.period,
  });

  factory TrackAnalytics.fromJson(Map<String, dynamic> json) => TrackAnalytics(
        totalPlays: json['totalPlays'] ?? 0,
        dailyStats: (json['dailyStats'] as List? ?? [])
            .map((i) => DailyStat.fromJson(i))
            .toList(),
        deviceStats: (json['deviceStats'] as List? ?? [])
            .map((i) => DeviceStat.fromJson(i))
            .toList(),
        period: json['period'] ?? 30,
      );
}
