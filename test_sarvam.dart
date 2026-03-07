import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  final response = await http.post(
    Uri.parse('https://api.sarvam.ai/text-to-speech'),
    headers: {
      'Content-Type': 'application/json',
      'api-subscription-key': 'sk_cy9lcdh9_H8d2OtLgNoXExA9zaFhZsoWZ',
    },
    body: jsonEncode({
      'inputs': ['Hello'],
      'target_language_code': 'en-IN',
      'speaker': 'rahul',
      'pace': 1.1,
      'speech_sample_rate': 16000,
      'enable_preprocessing': true,
      'model': 'bulbul:v3'
    }),
  );
  print(response.statusCode);
  if (response.statusCode != 200) {
      print(jsonDecode(response.body)['error']['message']);
  }
}
