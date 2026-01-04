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
    return PodcastModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      host: json['host'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      duration: Duration(seconds: json['duration']),
      category: json['category'],
      publishDate: DateTime.parse(json['publishDate']),
      episodeNumber: json['episodeNumber'],
      totalEpisodes: json['totalEpisodes'],
      isLiked: json['isLiked'] ?? false,
      playCount: json['playCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      seriesId: json['seriesId'],
      seriesTitle: json['seriesTitle'],
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

