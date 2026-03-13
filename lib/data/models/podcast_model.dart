import '../../core/config/api_config.dart';

class PodcastModel {
  final String id;
  final String title;
  final String description;
  final String host;
  final String imageUrl;
  final String audioUrl;
  final Duration duration;
  final String category;
  final DateTime publishDate;
  final int episodeNumber;
  final int totalEpisodes;
  final bool isLiked;
  final int playCount;
  final List<String> tags;
  final String seriesId;
  final String seriesTitle;

  PodcastModel({
    required this.id,
    required this.title,
    required this.description,
    required this.host,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.category,
    required this.publishDate,
    required this.episodeNumber,
    required this.totalEpisodes,
    this.isLiked = false,
    this.playCount = 0,
    this.tags = const [],
    required this.seriesId,
    required this.seriesTitle,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    // Handle populated artist/host field
    String hostName = '';
    if (json['artist'] is Map) {
      hostName = json['artist']['name'] ?? '';
    } else {
      hostName = json['host']?.toString() ?? json['artist']?.toString() ?? '';
    }

    final rawImage = json['imageUrl'] ?? json['coverArt'] ?? json['image'] ?? '';
    final rawAudio = json['audioFile'] ?? json['audioFileUrl'] ?? json['audioUrl'] ?? '';

    return PodcastModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      host: hostName,
      imageUrl: ApiConfig.resolveUrl(rawImage is String ? rawImage : ''),
      audioUrl: ApiConfig.resolveUrl(rawAudio is String ? rawAudio : ''),
      duration: Duration(seconds: (json['duration'] ?? 0) is int ? json['duration'] : (json['duration'] as num).toInt()),
      category: json['category']?.toString() ?? json['genre']?.toString() ?? '',
      publishDate: json['publishDate'] != null
          ? DateTime.tryParse(json['publishDate'].toString()) ?? DateTime.now()
          : json['releaseDate'] != null
              ? DateTime.tryParse(json['releaseDate'].toString()) ?? DateTime.now()
              : DateTime.now(),
      episodeNumber: json['episodeNumber'] ?? json['trackNumber'] ?? 1,
      totalEpisodes: json['totalEpisodes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      playCount: json['playCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      seriesId: json['seriesId']?.toString() ?? json['album']?.toString() ?? '',
      seriesTitle: json['seriesTitle']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'host': host,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'category': category,
      'publishDate': publishDate.toIso8601String(),
      'episodeNumber': episodeNumber,
      'totalEpisodes': totalEpisodes,
      'isLiked': isLiked,
      'playCount': playCount,
      'tags': tags,
      'seriesId': seriesId,
      'seriesTitle': seriesTitle,
    };
  }
}
