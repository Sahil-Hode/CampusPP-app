import 'dart:convert';
import 'package:http/http.dart' as http;

class VisionService {
  static const String _apiKey =
      'YOUR_OPENAI_API_KEY';

  /// Analyzes an image using OpenAI GPT-4o Vision API.
  /// [imageBase64] — base64-encoded image bytes (JPEG/PNG).
  /// Returns a descriptive text of what the image contains.
  static Future<String> analyzeImage(String imageBase64) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a visual analysis assistant. Describe what you see in the image in detail. '
              'Identify specific objects, brands, products, stickers, labels, text, and their characteristics. '
              'Be precise — if you see AirPods, say "Apple AirPods" not just "earbuds". '
              'If you see a sticker, describe what is on the sticker. '
              'If you see text, read and include it. '
              'If you see a specific product, name it exactly. Keep the description concise but accurate, '
              'in 2-3 sentences maximum.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Analyze this image carefully. What objects, stickers, labels, text, or products do you see? Be specific and precise.',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$imageBase64',
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'max_tokens': 300,
      'temperature': 0.2,
    });

    try {
      print('[VisionService] Sending image to OpenAI GPT-4o Vision...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );

      print('[VisionService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices']?[0]?['message']?['content'] as String?;
        print('[VisionService] GPT-4o says: $content');
        return content ?? 'Could not analyze the image.';
      } else {
        print('[VisionService] ERROR ${response.statusCode}: ${response.body}');
        return 'Failed to analyze image (status ${response.statusCode}).';
      }
    } catch (e) {
      print('[VisionService] EXCEPTION: $e');
      return 'Failed to analyze image.';
    }
  }
}
