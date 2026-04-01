import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class SarvamAnalysisResult {
  final bool success;
  final String? originalText;
  final String? translatedText;
  final String? summary;
  final String? language;
  final String? error;
  final Map<String, dynamic> rawData;

  SarvamAnalysisResult({
    required this.success,
    this.originalText,
    this.translatedText,
    this.summary,
    this.language,
    this.error,
    this.rawData = const {},
  });

  factory SarvamAnalysisResult.fromJson(Map<String, dynamic> json) {
    // If the actual payload is wrapped in a "data", "result", or similar object, use that
    final payload = json['data'] is Map<String, dynamic> 
        ? json['data'] as Map<String, dynamic>
        : (json['result'] is Map<String, dynamic> 
            ? json['result'] as Map<String, dynamic>
            : json);

    // Try multiple possible field names the backend may use
    String? extractOriginal() {
      return payload['originalText']
          ?? payload['original_text']
          ?? payload['extractedText']
          ?? payload['extracted_text']
          ?? payload['text']
          ?? payload['content']
          ?? payload['ocr_text']
          ?? payload['ocrText']
          ?? json['originalText']; // check outer json too
    }

    String? extractTranslated() {
      return payload['translatedText']
          ?? payload['translated_text']
          ?? payload['translation']
          ?? payload['translatedContent']
          ?? payload['translated_content']
          ?? json['translatedText'];
    }

    String? extractSummary() {
      return payload['summary']
          ?? payload['analysis']
          ?? payload['explanation']
          ?? payload['description']
          ?? payload['analysisResult']
          ?? payload['analysis_result']
          ?? json['summary']
          ?? json['explanation'];
    }

    return SarvamAnalysisResult(
      success: json['success'] ?? payload['success'] ?? false,
      originalText: extractOriginal(),
      translatedText: extractTranslated(),
      summary: extractSummary(),
      language: payload['language'] ?? payload['targetLanguage'] ?? json['language'],
      error: json['error'] ?? payload['error'] ?? json['message'],
      rawData: json,
    );
  }

  /// Check if any meaningful content was returned
  bool get hasContent =>
      (originalText != null && originalText!.isNotEmpty) ||
      (translatedText != null && translatedText!.isNotEmpty) ||
      (summary != null && summary!.isNotEmpty);
}

class SarvamService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  /// Analyze handwritten notes / documents via Sarvam AI.
  ///
  /// [filePath] – absolute path to the file on disk.
  /// [language] – target language for translation (default: English).
  static Future<SarvamAnalysisResult> analyzeNotes(
    String filePath, {
    String language = 'English',
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No auth token found. Please log in.');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: $filePath');
    }

    final uri = Uri.parse('$_baseUrl/sarvam/analyze');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Determine content type from extension
    final ext = filePath.toLowerCase().split('.').last;
    MediaType contentType;
    switch (ext) {
      case 'pdf':
        contentType = MediaType('application', 'pdf');
        break;
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      default:
        contentType = MediaType('application', 'octet-stream');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'notes', // field name expected by the backend
        filePath,
        contentType: contentType,
      ),
    );

    request.fields['language'] = language;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('📄 [SarvamService] Raw API response: ${response.body}');
      print('📄 [SarvamService] Parsed keys: ${json.keys.toList()}');
      return SarvamAnalysisResult.fromJson(json);
    } else {
      // Try to parse error from body
      try {
        final errJson = jsonDecode(response.body);
        throw Exception(
          errJson['error'] ?? 'Analysis failed (${response.statusCode})',
        );
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }
}
