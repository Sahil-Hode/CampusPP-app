import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/quiz_model.dart';

class QuizService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<QuizGenerateResult> generateQuiz({
    required String learningPathId,
    required int courseIndex,
    required int stepIndex,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/quiz/generate/$learningPathId/$courseIndex/$stepIndex';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final body = response.body;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(body);
      final quiz = json['quiz'] != null ? QuizData.fromJson(json['quiz']) : null;
      return QuizGenerateResult(
        quiz: quiz,
        alreadyPassed: json['alreadyPassed'] == true,
        message: json['message'],
        cooldownUntil: null,
        remainingMinutes: null,
        moduleLocked: false,
      );
    }

    if (response.statusCode == 403) {
      final json = jsonDecode(body);
      final cooldownUntil = json['cooldownUntil'] != null
          ? DateTime.tryParse(json['cooldownUntil'])
          : null;
      final remainingMinutes = json['remainingMinutes'];
      final moduleLocked = json['message']?.toString().contains('module is locked') == true ||
          json['message']?.toString().contains('module') == true;
      return QuizGenerateResult(
        quiz: null,
        alreadyPassed: false,
        message: json['message'],
        cooldownUntil: cooldownUntil,
        remainingMinutes: remainingMinutes,
        moduleLocked: moduleLocked,
      );
    }

    final json = body.isNotEmpty ? jsonDecode(body) : {};
    throw Exception(json['message'] ?? 'Failed to generate quiz');
  }

  static Future<QuizSubmitResult> submitQuiz({
    required String quizId,
    required List<Map<String, int>> answers,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/quiz/submit/$quizId';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'answers': answers}),
    );

    final body = response.body;
    if (response.statusCode == 200) {
      final json = jsonDecode(body);
      return QuizSubmitResult(
        passed: json['passed'] == true,
        score: json['score'] ?? 0,
        message: json['message'] ?? '',
        cooldownUntil: json['cooldownUntil'] != null ? DateTime.tryParse(json['cooldownUntil']) : null,
        moduleCompleted: json['moduleCompleted'] == true,
        nextModule: json['nextModule'],
      );
    }

    final json = body.isNotEmpty ? jsonDecode(body) : {};
    throw Exception(json['message'] ?? 'Failed to submit quiz');
  }

  static Future<Map<String, QuizStatusStep>> getLearningPathQuizStatus(String learningPathId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/quiz/status/$learningPathId';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'];
      final modules = data?['modules'] as List? ?? [];
      final Map<String, QuizStatusStep> map = {};
      for (final m in modules) {
        final cIdx = m['moduleIndex'] ?? 0;
        final steps = m['steps'] as List? ?? [];
        for (final s in steps) {
          final step = QuizStatusStep.fromJson(cIdx, s);
          map['${step.courseIndex}_${step.stepIndex}'] = step;
        }
      }
      return map;
    }

    final json = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(json['message'] ?? 'Failed to load quiz status');
  }

  static Future<QuizOverviewSummary> getOverviewSummary() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/quiz/overview';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final summary = json['data']?['summary'] ?? {};
      return QuizOverviewSummary.fromJson(summary);
    }

    final json = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(json['message'] ?? 'Failed to load quiz overview');
  }

  static Future<QuizScoreSummary> getScoreSummary() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/quiz/score';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? {};
      return QuizScoreSummary.fromJson(data);
    }

    final json = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(json['message'] ?? 'Failed to load quiz score');
  }
}
