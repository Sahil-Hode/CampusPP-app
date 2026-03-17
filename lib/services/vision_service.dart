import 'dart:convert';
import 'package:http/http.dart' as http;

class VisionService {
  static const String _apiKey = 'AIzaSyCuTgH-Dl8d_24oUEXrEKXJ79Vhd2VMV_o';

  /// Analyzes an image using Google Cloud Vision API.
  /// [imageBase64] — base64-encoded image bytes (JPEG/PNG).
  /// Returns a descriptive text of what the image contains.
  static Future<String> analyzeImage(String imageBase64) async {
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey',
    );

    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': imageBase64},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 10},
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 5},
            {'type': 'WEB_DETECTION', 'maxResults': 5},
          ],
        }
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final annotations = data['responses']?[0];
      if (annotations == null) return 'Could not analyze the image.';

      final parts = <String>[];

      // Labels
      final labels = annotations['labelAnnotations'] as List?;
      if (labels != null && labels.isNotEmpty) {
        final labelNames = labels
            .take(6)
            .map((l) => l['description'] as String)
            .toList();
        parts.add('Labels: ${labelNames.join(', ')}');
      }

      // Objects
      final objects = annotations['localizedObjectAnnotations'] as List?;
      if (objects != null && objects.isNotEmpty) {
        final objNames = objects
            .take(5)
            .map((o) => o['name'] as String)
            .toSet()
            .toList();
        parts.add('Objects: ${objNames.join(', ')}');
      }

      // Web entities
      final web = annotations['webDetection'];
      if (web != null) {
        final entities = web['webEntities'] as List?;
        if (entities != null && entities.isNotEmpty) {
          final webNames = entities
              .where((e) => e['description'] != null)
              .take(5)
              .map((e) => e['description'] as String)
              .toList();
          if (webNames.isNotEmpty) {
            parts.add('Related topics: ${webNames.join(', ')}');
          }
        }
        final bestGuess = web['bestGuessLabels'] as List?;
        if (bestGuess != null && bestGuess.isNotEmpty) {
          parts.add('Best guess: ${bestGuess[0]['label']}');
        }
      }

      return parts.isNotEmpty
          ? parts.join('. ')
          : 'No recognizable content found.';
    } else {
      print('Vision API error: ${response.statusCode} - ${response.body}');
      return 'Failed to analyze image.';
    }
  }
}
