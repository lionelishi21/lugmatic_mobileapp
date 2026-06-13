import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lugmatic_flutter/data/models/rhythm_model.dart';
import 'package:lugmatic_flutter/data/services/auth_service.dart';

class RhythmService {
  final String baseUrl;
  final AuthService _authService;

  RhythmService({required this.baseUrl, required AuthService authService})
      : _authService = authService;

  Future<List<RhythmModel>> getRhythms({String status = 'active'}) async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('$baseUrl/api/rhythms?status=$status');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = data['data'] as List;
          return items.map((e) => RhythmModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting rhythms: $e');
      return [];
    }
  }
}
