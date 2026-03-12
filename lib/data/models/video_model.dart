class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String artistId;
  final String artistName;
  final String? songId;
  final int views;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.artistId,
    required this.artistName,
    this.songId,
    this.views = 0,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    String artistId = '';
    String artistName = '';

    if (json['artist'] is Map) {
      artistId = json['artist']['_id'] ?? json['artist']['id'] ?? '';
      artistName = json['artist']['name'] ?? '';
    } else {
      artistId = json['artist']?.toString() ?? '';
    }

    return VideoModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      artistId: artistId,
      artistName: artistName,
      songId: json['song']?.toString(),
      views: json['views'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'artistId': artistId,
      'artistName': artistName,
      'songId': songId,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
