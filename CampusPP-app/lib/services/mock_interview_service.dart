import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/mock_interview_model.dart';

class MockInterviewService {
  static const String _baseUrl = 'https://techxpression-hackathon.onrender.com/api';
  // static const String _baseUrl = 'http://localhost:3000/api'; // Localhost for debugging

  static Future<InterviewSession> startInterview({
    String resumeSource = 'profile',
    String? resumePath,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    http.Response response;
    if (resumeSource == 'upload') {
      if (resumePath == null) {
        throw Exception('Please select a resume to upload.');
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/mock-interview/start'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['resumeSource'] = 'upload';
      request.files.add(await http.MultipartFile.fromPath('resume', resumePath));
      final streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } else {
      response = await http.post(
        Uri.parse('$_baseUrl/mock-interview/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'resumeSource': 'profile'}),
      );
    }

    print('Start Interview Status: ${response.statusCode}');
    print('Start Interview Body: ${response.body}');

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return InterviewSession.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to start interview');
    }
  }

  static Future<InterviewResponse> sendAnswer(String sessionId, String message) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$_baseUrl/mock-interview/text-answer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sessionId': sessionId,
        'message': message,
      }),
    );

    print('Send Answer Status: ${response.statusCode}');
    print('Send Answer Body: ${response.body}');

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return InterviewResponse.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to process answer');
    }
  }

  static Future<InterviewFeedback> endInterview(String sessionId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$_baseUrl/mock-interview/end'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sessionId': sessionId,
      }),
    );

    print('End Interview Status: ${response.statusCode}');
    print('End Interview Body: ${response.body}');

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return InterviewFeedback.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to end interview');
    }
  }
}
