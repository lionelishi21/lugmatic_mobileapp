import '../models/mix_model.dart';
import '../../core/network/api_client.dart';

class MixerService {
  final ApiClient _apiClient;
  MixerService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<MixModel> generateMix({
    required String mood,
    String? genre,
    int songCount = 8,
  }) async {
    try {
      final response = await _apiClient.dio.post('/mixer/generate', data: {
        'mood': mood,
        if (genre != null) 'genre': genre,
        'songCount': songCount,
      });
      final data = response.data['data'];
      return MixModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to generate mix: $e');
    }
  }

  Future<MixModel> saveMix(MixModel mix) async {
    try {
      final response = await _apiClient.dio.post('/mixer/save', data: {
        'mixName': mix.mixName,
        'mood': mix.mood,
        if (mix.genre != null) 'genre': mix.genre,
        'songs': mix.songs.map((s) => s.toJson()).toList(),
        'transitions': mix.transitions.map((t) => t.toJson()).toList(),
      });
      return MixModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to save mix: $e');
    }
  }

  Future<List<MixModel>> getMixes() async {
    try {
      final response = await _apiClient.dio.get('/mixer/mixes');
      final list = response.data['data'] as List? ?? [];
      return list.map((m) => MixModel.fromJson(m)).toList();
    } catch (e) {
      throw Exception('Failed to load mixes: $e');
    }
  }

  Future<void> deleteMix(String id) async {
    try {
      await _apiClient.dio.delete('/mixer/mixes/$id');
    } catch (e) {
      throw Exception('Failed to delete mix: $e');
    }
  }
}
