import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Correctly placed import
import 'auth_service.dart';
import '../models/resume_analysis_model.dart';

class ResumeService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<ResumeAnalysisResponse> analyzeResume(String filePath) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final uri = Uri.parse('$_baseUrl/resume/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    final mimeType = filePath.toLowerCase().endsWith('.pdf') 
        ? MediaType.parse('application/pdf')
        : MediaType.parse('application/msword'); // Fallback for doc/docx

    // Add file
    request.files.add(await http.MultipartFile.fromPath(
      'resume', 
      filePath,
      contentType: mimeType,
    ));

    print('Sending resume to $uri');
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Resume Analysis Status: ${response.statusCode}');
      print('Resume Analysis Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ResumeAnalysisResponse.fromJson(json);
      } else {
        throw Exception('Analysis failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Resume Analysis Error: $e');
      throw Exception('Connection error: $e');
    }
  }
}
