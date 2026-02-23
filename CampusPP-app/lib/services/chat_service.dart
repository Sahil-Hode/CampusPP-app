import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static const String _baseUrl = 'https://techxpression-hackathon.onrender.com/api';

  static Future<String> sendMessage(String message, {String systemPrompt = "You are a helpful academic assistant."}) async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'message': message,
      'systemPrompt': systemPrompt,
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mistral-bot/chat'),
        headers: headers,
        body: body,
      );

      print('Chat Bot Status: ${response.statusCode}');
      print('Chat Bot Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data']['reply'] ?? "I didn't get that.";
        } else {
           throw Exception(json['message'] ?? 'API returned success:false');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Chat Service Error: $e');
      rethrow; // Pass error to UI
    }
  }
}
