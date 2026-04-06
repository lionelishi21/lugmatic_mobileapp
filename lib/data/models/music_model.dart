import '../../core/config/api_config.dart';

class MusicModel {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String imageUrl;
  final String audioUrl;
  final String videoUrl;
  final Duration duration;
  final String genre;
  final bool isLiked;
  final int playCount;
  final DateTime releaseDate;
  final bool isArtistVerified;

  MusicModel({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId = '',
    required this.album,
    required this.imageUrl,
    required this.audioUrl,
    this.videoUrl = '',
    required this.duration,
    required this.genre,
    this.isLiked = false,
    this.playCount = 0,
    required this.releaseDate,
    this.isArtistVerified = false,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    // Handle populated artist (object with name) or plain string
    String artistName = '';
    String artistId = '';
    bool isVerified = false;
    if (json['artist'] is Map) {
      artistName = json['artist']['name'] ?? '';
      artistId = json['artist']['_id'] ?? json['artist']['id'] ?? '';
      isVerified = json['artist']['isVerified'] ?? false;
    } else {
      artistName = json['artist']?.toString() ?? '';
    }

    // Handle populated album (object with name) or plain string
    String albumName = '';
    String albumCoverArt = '';
    if (json['album'] is Map) {
      albumName = json['album']['name'] ?? '';
      albumCoverArt = json['album']['coverArt'] ?? '';
    } else {
      albumName = json['album']?.toString() ?? '';
    }

    // Image: prefer already-resolved coverArtUrl, fall back to raw coverArt key/path
    final rawImage = json['coverArtUrl'] ?? json['coverArt'] ?? albumCoverArt ?? '';
    final imageUrl = ApiConfig.resolveUrl(rawImage is String ? rawImage : '');

    // Audio URL: prefer already-resolved audioFileUrl, fall back to audioFile (raw key/path)
    final rawAudio = json['audioFileUrl'] ?? json['audioFile'] ?? json['audioUrl'] ?? '';
    final audioUrl = ApiConfig.resolveUrl(rawAudio is String ? rawAudio : '');


    // Handle populated genre (object with name) or plain string/ObjectId
    String genreName = '';
    if (json['genre'] is Map) {
      genreName = json['genre']['name'] ?? '';
    } else {
      genreName = json['genre']?.toString() ?? '';
    }

    return MusicModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      artist: artistName,
      artistId: artistId,
      album: albumName,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      videoUrl: ApiConfig.resolveUrl(json['videoUrl'] ?? json['videoFileUrl'] ?? ''),
      duration: Duration(
        seconds: (json['duration'] ?? 0) is int
            ? json['duration']
            : (json['duration'] as num).toInt(),
      ),
      genre: genreName,
      isLiked: json['isLiked'] ?? false,
      playCount: json['playCount'] ?? 0,
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isArtistVerified: isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'duration': duration.inSeconds,
      'genre': genre,
      'isLiked': isLiked,
      'playCount': playCount,
      'releaseDate': releaseDate.toIso8601String(),
      'isArtistVerified': isArtistVerified,
    };
  }
}
