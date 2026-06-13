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
        id: json['_id']?.toString() ?? '',
        name: json['title']?.toString() ?? json['name']?.toString() ?? 'Unknown Track',
        coverArt: json['coverArt']?.toString() ?? json['coverImage']?.toString(),
        coverArtUrl: json['coverArtUrl']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        playCount: int.tryParse(json['plays']?.toString() ?? json['playCount']?.toString() ?? '0') ?? 0,
        uploadSource: json['uploadSource']?.toString(),
        createdAt: json['createdAt'] != null 
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        share: json['share'] != null ? double.tryParse(json['share'].toString()) : null,
        role: json['role']?.toString(),
        videoUrl: json['videoUrl']?.toString(),
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
