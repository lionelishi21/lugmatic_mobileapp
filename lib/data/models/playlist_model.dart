// lib/features/home/data/models/playlist_model.dart
import '../../../../data/models/music_model.dart';
import '../../core/config/api_config.dart';

class PlaylistModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String type; // 'playlist', 'album', 'station'
  final String? description;
  final String? ownerId;
  final String? ownerName;
  final bool isRecommended;
  final List<MusicModel> songs;

  PlaylistModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.type,
    this.description,
    this.ownerId,
    this.ownerName,
    this.isRecommended = false,
    this.songs = const [],
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    var songsList = <MusicModel>[];
    if (json['songs'] != null) {
      songsList = (json['songs'] as List)
          // Songs can come back as raw ObjectId strings when not populated
          // (e.g. a playlist fetched without a songs.populate) — skip those
          // instead of crashing.
          .whereType<Map>()
          .map((i) => MusicModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    // `owner` is only populated on some endpoints (e.g. public/admin playlist
    // listings) — on "my playlists" it's just a raw ObjectId string, since the
    // owner is always the requesting user. Guard against indexing a String.
    final owner = json['owner'];
    final ownerMap = owner is Map ? owner : null;

    // Backend's mediaEnricher exposes the resolved cover art as `coverArtUrl`
    // (falls back to the raw `coverArt` key, or the legacy `artwork.thumbnail`).
    // Resolve here so every consumer gets a ready-to-use absolute URL.
    final artwork = json['artwork'];
    final rawImage = json['imageUrl'] ??
        json['coverArtUrl'] ??
        json['coverArt'] ??
        (artwork is Map ? artwork['thumbnail'] : null) ??
        '';
    final imageUrl = ApiConfig.resolveUrl(rawImage is String ? rawImage : '');

    return PlaylistModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? json['description'] ?? '',
      imageUrl: imageUrl,
      type: json['type'] ?? 'playlist',
      description: json['description'],
      ownerId: ownerMap?['_id'] ?? (owner is String ? owner : null),
      ownerName: ownerMap != null ? '${ownerMap['firstName'] ?? ''} ${ownerMap['lastName'] ?? ''}'.trim() : null,
      isRecommended: json['isRecommended'] ?? false,
      songs: songsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'type': type,
      'description': description,
      'isRecommended': isRecommended,
    };
  }
}
