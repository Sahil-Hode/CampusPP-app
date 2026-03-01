import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ARGenerationService {
  static const String _baseUrl =
      'https://campuspp-f7qx.onrender.com/api/tripo3d';

  // POST /api/tripo3d/image-to-model — upload image, generate & save model
  static Future<Map<String, dynamic>?> generateModelFromImage(
      File imageFile, {String name = 'My 3D Model'}) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/image-to-model'));

      request.fields['name'] = name;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to generate model');
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(
            responseData['message'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating model: $e');
    }
  }

  // GET /api/tripo3d/models — get all saved models from backend
  static Future<List<Map<String, dynamic>>> getAllModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> models = responseData['data'] ?? [];
          return models.cast<Map<String, dynamic>>();
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch models');
        }
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }

  // GET /api/tripo3d/models/:id — get specific model by MongoDB _id
  static Future<Map<String, dynamic>?> getModelById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>?;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch model');
        }
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching model: $e');
    }
  }

  // DELETE /api/tripo3d/models/:id — delete specific model by MongoDB _id
  static Future<bool> deleteModel(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/models/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting model: $e');
    }
  }

  // GET /api/tripo3d/task/:taskId — check live Tripo3D task status
  static Future<Map<String, dynamic>?> checkTaskStatus(
      String taskId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/task/$taskId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return (responseData['task'] ??
              responseData['data'] ??
              responseData['result']) as Map<String, dynamic>?;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to check task status');
        }
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking task status: $e');
    }
  }
}
