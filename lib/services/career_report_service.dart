import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CareerReportService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<Map<String, dynamic>> getCareerReportSummary() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url =
        '$_baseUrl/career-report/summary?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
    }
    throw Exception('Failed to load career report');
  }
}
