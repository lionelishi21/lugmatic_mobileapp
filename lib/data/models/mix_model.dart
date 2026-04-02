class MixTransition {
  final int afterSongIndex;
  final String text;
  final String? audioUrl;

  MixTransition({required this.afterSongIndex, required this.text, this.audioUrl});

  factory MixTransition.fromJson(Map<String, dynamic> json) => MixTransition(
        afterSongIndex: json['afterSongIndex'] ?? 0,
        text: json['text'] ?? '',
        audioUrl: json['audioUrl'],
      );

  Map<String, dynamic> toJson() => {
        'afterSongIndex': afterSongIndex,
        'text': text,
        if (audioUrl != null) 'audioUrl': audioUrl,
      };
}

class MixSong {
  final String? songId;
  final String name;
  final String artist;
  final String audioFile;
  final String? coverArt;
  final int? duration;

  MixSong({
    this.songId,
    required this.name,
    required this.artist,
    required this.audioFile,
    this.coverArt,
    this.duration,
  });

  factory MixSong.fromJson(Map<String, dynamic> json) => MixSong(
        songId: json['songId'],
        name: json['name'] ?? 'Unknown',
        artist: json['artist'] ?? 'Unknown',
        audioFile: json['audioFile'] ?? '',
        coverArt: json['coverArt'],
        duration: json['duration'],
      );

  Map<String, dynamic> toJson() => {
        if (songId != null) 'songId': songId,
        'name': name,
        'artist': artist,
        'audioFile': audioFile,
        if (coverArt != null) 'coverArt': coverArt,
        if (duration != null) 'duration': duration,
      };
}

class MixModel {
  final String? id;
  final String mixName;
  final String mood;
  final String? genre;
  final List<MixSong> songs;
  final List<MixTransition> transitions;
  final int playCount;
  final DateTime? createdAt;

  MixModel({
    this.id,
    required this.mixName,
    required this.mood,
    this.genre,
    required this.songs,
    required this.transitions,
    this.playCount = 0,
    this.createdAt,
  });

  factory MixModel.fromJson(Map<String, dynamic> json) => MixModel(
        id: json['_id'],
        mixName: json['mixName'] ?? json['name'] ?? 'My Mix',
        mood: json['mood'] ?? 'hype',
        genre: json['genre'],
        songs: (json['songs'] as List? ?? []).map((s) => MixSong.fromJson(s)).toList(),
        transitions: (json['transitions'] as List? ?? []).map((t) => MixTransition.fromJson(t)).toList(),
        playCount: json['playCount'] ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}
