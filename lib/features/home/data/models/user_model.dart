// lib/features/home/data/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final List<String> favoritePlaylistIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.favoritePlaylistIds = const [],
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      favoritePlaylistIds: List<String>.from(json['favoritePlaylistIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'favoritePlaylistIds': favoritePlaylistIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    List<String>? favoritePlaylistIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoritePlaylistIds: favoritePlaylistIds ?? this.favoritePlaylistIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}