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
        throw Exception(data['message'] ??
            'Execution failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('CodeRunnerService.executeCode error: $e');
      throw Exception('Execution error: $e');
    }
  }

  /// Explain Code
  static Future<Map<String, dynamic>> explainCode(
      {required String code, String? language}) async {
    final url = Uri.parse('$baseUrl/explain');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'code': code, 'language': language ?? 'unknown'}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to explain code');
  }

  /// Debug Code
  static Future<Map<String, dynamic>> debugCode(
      {required String code, String? language, String? error}) async {
    final url = Uri.parse('$baseUrl/debug');
    final Map<String, dynamic> body = {
      'code': code,
      'language': language ?? 'unknown'
    };
    if (error != null) body['error'] = error;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to debug code');
  }

  /// Review Code
  static Future<Map<String, dynamic>> reviewCode(
      {required String code, String? language}) async {
    final url = Uri.parse('$baseUrl/review');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'code': code, 'language': language ?? 'unknown'}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to review code');
  }

  /// Explain and Debug Code
  static Future<Map<String, dynamic>> explainAndDebugCode(
      {required String code, required String error, String? language}) async {
    final url = Uri.parse('$baseUrl/explain-and-debug');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(
          {'code': code, 'error': error, 'language': language ?? 'unknown'}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['message'] ??
        'Failed to explain and debug code');
  }

  /// Improve Code
  static Future<Map<String, dynamic>> improveCode(
      {required String code, String? language}) async {
    final url = Uri.parse('$baseUrl/improve');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'code': code, 'language': language ?? 'unknown'}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to improve code');
  }

  /// Generate Challenge
  static Future<Map<String, dynamic>> generateChallenge(
      {String? language, String? difficulty, String? topic}) async {
    final url = Uri.parse('$baseUrl/generate-challenge');
    final Map<String, dynamic> body = {};
    if (language != null) body['language'] = language;
    if (difficulty != null) body['difficulty'] = difficulty;
    if (topic != null) body['topic'] = topic;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to generate challenge');
  }

  // ── GITHUB INTEGRATION ────────────────────────────────────────────────────

  /// Get the GitHub OAuth URL to open in a browser
  static String githubOAuthUrl({String? fileName, String? language}) {
    final base = '${AuthService.baseUrl.replaceAll('/api', '')}/api/auth/github';
    final params = <String, String>{};
    if (fileName != null) params['fileName'] = fileName;
    if (language != null) params['language'] = language;
    params['returnUrl'] = '/code-ide';
    return Uri.parse(base).replace(queryParameters: params).toString();
  }

  /// List GitHub repos for authenticated user
  static Future<List<Map<String, dynamic>>> listGithubRepos(
      {required String token}) async {
    final url = Uri.parse('$baseUrl/github/repos');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to list repos');
  }

  /// Create a new GitHub repo
  static Future<Map<String, dynamic>> createGithubRepo({
    required String token,
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    final url = Uri.parse('$baseUrl/github/repos');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': name,
        'description': description ?? 'Created from Campus++ Code IDE',
        'isPrivate': isPrivate,
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to create repo');
  }

  /// Push code to a GitHub repo
  static Future<Map<String, dynamic>> pushToGithub({
    required String token,
    required String repo,
    required String fileName,
    required String code,
    String? message,
    String branch = 'main',
  }) async {
    final url = Uri.parse('$baseUrl/github/push');
    final body = <String, dynamic>{
      'repo': repo,
      'fileName': fileName,
      'code': code,
      'branch': branch,
    };
    if (message != null) body['message'] = message;

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to push to GitHub');
  }
}
