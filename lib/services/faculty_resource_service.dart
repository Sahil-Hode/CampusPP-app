import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/faculty_resource_model.dart';
import 'auth_service.dart';

class FacultyResourceService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<List<FacultyResource>> getResources({int page = 1, int limit = 20, String? subject}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    String url = '$_baseUrl/faculty-resources?page=$page&limit=$limit';
    if (subject != null && subject.isNotEmpty) {
      url += '&subject=$subject';
    }

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
        return (json['data'] as List)
            .map((item) => FacultyResource.fromJson(item))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load faculty resources');
    }
  }

  static Future<void> uploadResource(File file, String title, String description, String subject) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/faculty-resources/upload'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['subject'] = subject;

    final extension = file.path.toLowerCase().split('.').last;
    MediaType contentType;
    if (extension == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (['jpg', 'jpeg'].contains(extension)) {
      contentType = MediaType('image', 'jpeg');
    } else if (extension == 'png') {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: contentType,
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201 && response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to upload resource');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  static Future<void> deleteResource(String id) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$_baseUrl/faculty-resources/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete resource');
    }
  }
}
