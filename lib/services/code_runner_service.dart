import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CodeRunnerService {
  static const String baseUrl = '${AuthService.baseUrl}/code-runner';

  /// Fetch supported languages from the backend
  static Future<List<Map<String, dynamic>>> getLanguages() async {
    final url = Uri.parse('$baseUrl/languages');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load languages: ${response.statusCode}');
      }
    } catch (e) {
      print('CodeRunnerService.getLanguages error: $e');
      throw Exception('Connection error: $e');
    }
  }

  /// Execute code
  static Future<Map<String, dynamic>> executeCode({
    required String language,
    required String code,
    String stdin = '',
  }) async {
    final url = Uri.parse('$baseUrl/execute');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'language': language,
          'code': code,
          'stdin': stdin,
        }),
      );

      print('CodeRunner Execute Status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Execution failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('CodeRunnerService.executeCode error: $e');
      throw Exception('Execution error: $e');
    }
  }
}
