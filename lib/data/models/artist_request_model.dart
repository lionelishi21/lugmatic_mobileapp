class ArtistRequestModel {
  final String id;
  final String artistName;
  final String genre;
  final String socialLink;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;

  ArtistRequestModel({
    required this.id,
    required this.artistName,
    required this.genre,
    required this.socialLink,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory ArtistRequestModel.fromJson(Map<String, dynamic> json) {
    return ArtistRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      artistName: json['artistName'] ?? '',
      genre: json['genre'] ?? '',
      socialLink: json['socialLink'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistName': artistName,
      'genre': genre,
      'socialLink': socialLink,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
