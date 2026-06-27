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
  final double averageRating;
  final int ratingCount;
  final double? userRating;
  final bool isFollowing;
  final bool isLive;
  final String? userId;

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
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.userRating,
    this.isFollowing = false,
    this.isLive = false,
    this.userId,
  });

  ArtistModel copyWith({
    int? followers,
    bool? isFollowing,
  }) {
    return ArtistModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      bio: bio,
      followers: followers ?? this.followers,
      genres: genres,
      isVerified: isVerified,
      location: location,
      socialLinks: socialLinks,
      totalSongs: totalSongs,
      totalAlbums: totalAlbums,
      rating: rating,
      averageRating: averageRating,
      ratingCount: ratingCount,
      userRating: userRating,
      isFollowing: isFollowing ?? this.isFollowing,
      isLive: isLive,
      userId: userId,
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    // Handle location: backend sends {city, country} object
    String locationStr = '';
    if (json['location'] is Map) {
      final loc = json['location'] as Map;
      final parts = <String>[
        if (loc['city'] != null && loc['city'].toString().isNotEmpty) loc['city'].toString(),
        if (loc['country'] != null && loc['country'].toString().isNotEmpty) loc['country'].toString(),
      ];
      locationStr = parts.join(', ');
    } else if (json['location'] is String) {
      locationStr = json['location'] ?? '';
    }

    // Handle followers: backend sends array of ObjectIds, use followerCount for count
    int followerCount = 0;
    if (json['followerCount'] != null) {
      followerCount = json['followerCount'] is int ? json['followerCount'] : (json['followerCount'] as num).toInt();
    } else if (json['followers'] is int) {
      followerCount = json['followers'];
    } else if (json['followers'] is List) {
      followerCount = (json['followers'] as List).length;
    }

    return ArtistModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'] ?? json['artwork'] ?? '',
      bio: json['bio'] ?? '',
      followers: followerCount,
      genres: List<String>.from(json['genres'] ?? []),
      isVerified: json['isVerified'] ?? false,
      location: locationStr,
      socialLinks: const [],
      totalSongs: json['songCount'] ?? json['totalSongs'] ?? 0,
      totalAlbums: json['albumCount'] ?? json['totalAlbums'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      userRating: json['userRating']?.toDouble(),
      isFollowing: json['isFollowing'] ?? false,
      isLive: json['isLive'] ?? false,
      userId: json['user']?['id'] ?? json['user']?['_id'],
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
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      if (userRating != null) 'userRating': userRating,
      'isFollowing': isFollowing,
      'isLive': isLive,
      if (userId != null) 'user': {'id': userId},
    };
  }
}

