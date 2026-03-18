class GenreModel {
  final String id;
  final String name;
  final String? image;
  final String? color;
  final int songCount;

  GenreModel({
    required this.id,
    required this.name,
    this.image,
    this.color,
    this.songCount = 0,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      color: json['color'],
      songCount: json['songCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'color': color,
      'songCount': songCount,
    };
  }
}
