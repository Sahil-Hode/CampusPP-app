import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Base URL from the user provided documentation
  static const String baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<Map<String, dynamic>> login(String studentId, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    
    print('Attempting login to: $url');
    print('Student ID: ${studentId.trim()}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'studentId': studentId.trim(),
          'password': password.trim(),
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Save token if present
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        // Error from server
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Login Exception: $e');
      throw Exception('Connection error: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('Token saved: ${token.substring(0, 10)}...'); 
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('Token removed');
  }
}
