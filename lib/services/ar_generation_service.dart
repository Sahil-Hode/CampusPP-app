import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ARGenerationService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api/tripo3d';

  static Future<String?> generateModelFromImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/image-to-model'));
      
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
          // The API might return 'pbr_model' or 'model_url'. We prefer 'pbr_model' based on the screenshot.
          return responseData['result']['pbr_model'] ?? responseData['result']['model_url'];
        } else {
          throw Exception(responseData['message'] ?? 'Failed to generate model');
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating model: $e');
    }
  }
}
