import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class UploadService {
  final ApiClient _apiClient;

  UploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> uploadContent({
    required File file,
    required File coverArt,
    required String title,
    required String type, // 'song' or 'podcast'
    required String genreId,
    String? description,
    String? videoFileKey,
    Function(double)? onProgress,
    // Record-label uploads only: either an existing artist's id, or a new
    // artist name to create as an unclaimed (label-managed) profile.
    String? artistId,
    String? unclaimedArtistName,
    bool isAiGenerated = false,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      String coverName = coverArt.path.split('/').last;

      final fields = <String, dynamic>{
        'title': title,
        'type': type,
        'genreId': genreId,
        'description': description ?? '',
        'isAiGenerated': isAiGenerated,
        'audioFile': await MultipartFile.fromFile(file.path, filename: fileName),
        'coverArt': await MultipartFile.fromFile(coverArt.path, filename: coverName),
      };
      if (videoFileKey != null) fields['videoFileKey'] = videoFileKey;
      if (artistId != null) fields['artist'] = artistId;
      if (unclaimedArtistName != null) fields['unclaimedArtistName'] = unclaimedArtistName;

      FormData formData = FormData.fromMap(fields);

      final response = await _apiClient.dio.post(
        '/artist/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      final data = response.data;
      return (data['data'] ?? data) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Search existing artists by name (record-label upload flow).
  Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final response = await _apiClient.dio.get(
        '/search/artists',
        queryParameters: {'q': query.trim()},
      );
      final body = response.data;
      final items = body['data'] ?? [];
      return (items as List).cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getGenres() async {
    try {
      final response = await _apiClient.dio.get('/genre/list');
      final body = response.data;
      final rawData = body['data'];
      final items = rawData is List ? rawData : rawData?['genres'] ?? body['genres'] ?? [];
      return items as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPresignedUrl({
    required String type, // 'music-video', 'song-audio', 'cover-art'
    required String filename,
    required String contentType,
  }) async {
    final response = await _apiClient.dio.post('/upload/presign/$type', data: {
      'filename': filename,
      'contentType': contentType,
    });
    final data = response.data;
    return (data['data'] ?? data) as Map<String, dynamic>;
  }

  Future<void> uploadToS3({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    // Use a separate Dio instance WITHOUT auth headers for S3 PUT
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length,
        },
      ),
      onSendProgress: onProgress != null
          ? (sent, total) => onProgress(total > 0 ? sent / total : 0)
          : null,
    );
  }

  Future<String> generateLyrics(String songId) async {
    final response = await _apiClient.dio.post('/song/$songId/generate-lyrics');
    final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
    return data['lyrics'] as String? ?? '';
  }

  /// Standalone lyrics save — not routed through /song/update, which blocks
  /// artists from saving anything once a song is approved/pending (the
  /// "must be rejected" moderation gate). Lyrics don't affect moderation.
  Future<void> updateSongLyrics(String songId, String lyrics) async {
    await _apiClient.dio.put('/song/$songId/lyrics', data: {'lyrics': lyrics});
  }

  Future<void> updateSongLyricsTiming(String songId, List<Map<String, dynamic>> lyricsLines) async {
    await _apiClient.dio.put('/song/$songId/lyrics-timing', data: {'lyricsLines': lyricsLines});
  }

  /// Returns a draft {lyricsLines, source} — not saved server-side. The
  /// caller reviews/edits then persists via updateSongLyricsTiming.
  Future<(List<Map<String, dynamic>>, String)> autoGenerateLyricsTiming(String songId) async {
    final response = await _apiClient.dio.post('/song/$songId/lyrics-timing/auto-generate');
    final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
    final lyricsLines = (data['lyricsLines'] as List).cast<Map<String, dynamic>>();
    final source = data['source'] as String? ?? 'unknown';
    return (lyricsLines, source);
  }
}
