class RhythmModel {
  final String id;
  final String name;
  final String producer;
  final String url;
  final String status;
  final String? coverImage;
  final String? bpm;

  const RhythmModel({
    required this.id,
    required this.name,
    required this.producer,
    required this.url,
    required this.status,
    this.coverImage,
    this.bpm,
  });

  factory RhythmModel.fromJson(Map<String, dynamic> json) {
    return RhythmModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Rhythm',
      producer: json['producer']?.toString() ?? 'Unknown',
      url: json['url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      coverImage: json['coverImage']?.toString(),
      bpm: json['bpm']?.toString(),
    );
  }
}
