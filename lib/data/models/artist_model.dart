class ArtistModel {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final int followers;
  final List<String> genres;
  final bool isVerified;
  final String location;
  final List<String> socialLinks;
  final int totalSongs;
  final int totalAlbums;
  final double rating;
  final bool isFollowing;

  ArtistModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.bio,
    this.followers = 0,
    required this.genres,
    this.isVerified = false,
    required this.location,
    this.socialLinks = const [],
    this.totalSongs = 0,
    this.totalAlbums = 0,
    this.rating = 0.0,
    this.isFollowing = false,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      bio: json['bio'],
      followers: json['followers'] ?? 0,
      genres: List<String>.from(json['genres'] ?? []),
      isVerified: json['isVerified'] ?? false,
      location: json['location'],
      socialLinks: List<String>.from(json['socialLinks'] ?? []),
      totalSongs: json['totalSongs'] ?? 0,
      totalAlbums: json['totalAlbums'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bio': bio,
      'followers': followers,
      'genres': genres,
      'isVerified': isVerified,
      'location': location,
      'socialLinks': socialLinks,
      'totalSongs': totalSongs,
      'totalAlbums': totalAlbums,
      'rating': rating,
      'isFollowing': isFollowing,
    };
  }
}

