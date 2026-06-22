import '../../core/config/api_config.dart';

class PodcastEpisode {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final Duration duration;
  final int episodeNumber;
  final int seasonNumber;
  final DateTime? publishDate;
  final bool isPublished;

  PodcastEpisode({
    required this.id,
    required this.title,
    this.description = '',
    required this.audioUrl,
    required this.duration,
    this.episodeNumber = 1,
    this.seasonNumber = 1,
    this.publishDate,
    this.isPublished = true,
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    // audioUrl added as convenience alias by enrichPodcastUrls on backend
    final rawAudio = json['audioUrl']?.toString() ??
        (json['audioFile'] is Map ? json['audioFile']['url']?.toString() : null) ??
        '';
    final rawDuration = json['duration'] ??
        (json['audioFile'] is Map ? json['audioFile']['duration'] : null);
    return PodcastEpisode(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      audioUrl: ApiConfig.resolveUrl(rawAudio),
      duration: Duration(seconds: _parseDurationSeconds(rawDuration)),
      episodeNumber: json['episodeNumber'] ?? 1,
      seasonNumber: json['seasonNumber'] ?? 1,
      publishDate: json['publishDate'] != null
          ? DateTime.tryParse(json['publishDate'].toString())
          : null,
      isPublished: json['isPublished'] ?? true,
    );
  }

  static int _parseDurationSeconds(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

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
  final List<PodcastEpisode> episodes;

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
    this.episodes = const [],
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    String hostName = '';
    if (json['artist'] is Map) {
      hostName = json['artist']['name'] ?? '';
    } else {
      hostName = json['host']?.toString() ?? json['artist']?.toString() ?? '';
    }

    final rawImage = json['imageUrl'] ?? json['coverArt'] ?? json['coverImage'] ?? json['image'] ?? '';

    // Parse episodes array (podcast is a series)
    final rawEpisodes = json['episodes'] as List? ?? [];
    final parsedEpisodes = rawEpisodes
        .map((e) => PodcastEpisode.fromJson(e as Map<String, dynamic>))
        .where((e) => e.isPublished && e.audioUrl.isNotEmpty)
        .toList();

    // Use first episode for the playable audio/duration — fall back to top-level fields
    final firstEp = parsedEpisodes.isNotEmpty ? parsedEpisodes.first : null;
    final rawAudio = json['audioUrl']?.toString() ??
        (json['audioFile'] is Map ? json['audioFile']['url']?.toString() : null) ??
        firstEp?.audioUrl ?? '';
    final rawDuration = json['duration'] ?? firstEp?.duration.inSeconds ?? 0;

    return PodcastModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      host: hostName,
      imageUrl: ApiConfig.resolveUrl(rawImage is String ? rawImage : ''),
      audioUrl: ApiConfig.resolveUrl(rawAudio),
      duration: firstEp?.duration ?? Duration(seconds: _parseDurationSeconds(rawDuration)),
      category: json['category']?.toString() ?? json['genre']?.toString() ?? '',
      publishDate: json['publishDate'] != null
          ? DateTime.tryParse(json['publishDate'].toString()) ?? DateTime.now()
          : json['releaseDate'] != null
              ? DateTime.tryParse(json['releaseDate'].toString()) ?? DateTime.now()
              : DateTime.now(),
      episodeNumber: firstEp?.episodeNumber ?? json['episodeNumber'] ?? json['trackNumber'] ?? 1,
      totalEpisodes: rawEpisodes.length > 0 ? rawEpisodes.length : (json['totalEpisodes'] ?? 0),
      isLiked: json['isLiked'] ?? false,
      playCount: json['playCount'] ?? json['totalPlayCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      seriesId: json['_id']?.toString() ?? json['seriesId']?.toString() ?? '',
      seriesTitle: json['title']?.toString() ?? json['seriesTitle']?.toString() ?? '',
      episodes: parsedEpisodes,
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

  static int _parseDurationSeconds(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
