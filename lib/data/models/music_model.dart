class MusicModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String imageUrl;
  final String audioUrl;
  final Duration duration;
  final String genre;
  final bool isLiked;
  final int playCount;
  final DateTime releaseDate;

  MusicModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.genre,
    this.isLiked = false,
    this.playCount = 0,
    required this.releaseDate,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    // Handle populated artist (object with name) or plain string
    String artistName;
    if (json['artist'] is Map) {
      artistName = json['artist']['name'] ?? '';
    } else {
      artistName = json['artist']?.toString() ?? '';
    }

    // Handle populated album (object with name) or plain string
    String albumName;
    String albumCoverArt = '';
    if (json['album'] is Map) {
      albumName = json['album']['name'] ?? '';
      albumCoverArt = json['album']['coverArt'] ?? '';
    } else {
      albumName = json['album']?.toString() ?? '';
    }

    // Image: prefer coverArt on the song, then album coverArt
    final imageUrl = json['coverArt'] ?? albumCoverArt;

    return MusicModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      artist: artistName,
      album: albumName,
      imageUrl: imageUrl is String ? imageUrl : '',
      audioUrl: json['audioFile'] ?? json['audioUrl'] ?? '',
      duration: Duration(seconds: (json['duration'] ?? 0) is int ? json['duration'] : (json['duration'] as num).toInt()),
      genre: json['genre'] ?? '',
      isLiked: json['isLiked'] ?? false,
      playCount: json['playCount'] ?? 0,
      releaseDate: json['releaseDate'] != null ? DateTime.tryParse(json['releaseDate'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'genre': genre,
      'isLiked': isLiked,
      'playCount': playCount,
      'releaseDate': releaseDate.toIso8601String(),
    };
  }
}

