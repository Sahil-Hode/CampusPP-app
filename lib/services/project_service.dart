import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProjectService {
  static const String baseUrl = '${AuthService.baseUrl}/projects';

  /// POST /api/projects/generate/:learningPathId
  /// Generates a project for the completed learning path
  static Future<Map<String, dynamic>> generateProject(String learningPathId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/generate/$learningPathId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('ProjectService.generateProject status: ${response.statusCode}');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data['data'] ?? data;
    } else {
      throw Exception(data['message'] ?? 'Failed to generate project (${response.statusCode})');
    }
  }

  /// GET /api/projects/by-id/:projectId
  /// Fetches full project details
  static Future<Map<String, dynamic>> getProject(String projectId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/by-id/$projectId');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('ProjectService.getProject status: ${response.statusCode}');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'] ?? data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch project (${response.statusCode})');
    }
  }

  /// POST /api/projects/:projectId/submit
  /// Submits a GitHub repo for evaluation
  static Future<Map<String, dynamic>> submitProject(String projectId, String repoUrl) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/$projectId/submit');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'repoUrl': repoUrl}),
    );

    print('ProjectService.submitProject status: ${response.statusCode}');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data['data'] ?? data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit project (${response.statusCode})');
    }
  }
}
