// lib/features/home/data/models/playlist_model.dart
import '../../../../data/models/music_model.dart';

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
          .map((i) => MusicModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return PlaylistModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['artwork']?['thumbnail'] ?? '',
      type: json['type'] ?? 'playlist',
      description: json['description'],
      ownerId: json['owner']?['_id'],
      ownerName: json['owner'] != null ? '${json['owner']['firstName']} ${json['owner']['lastName']}' : null,
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
