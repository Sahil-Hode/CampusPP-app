import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Integreted Keys (As provided)
  static const String mistralApiKey = 'J8puXD4IdLfYqAeVCJbFaqlM8OszNg65';
  static const String elevenLabsApiKey = 'sk_637c593411cce03d58c732b2d58c59b45d152e9a7d934c70';
  
  // Voice ID for "Adam" (Male - Standard)
  static const String elevenLabsVoiceId = 'pNInz6obpgDQGcFmaJgB'; 

  /// Sends the user input to Mistral AI and returns the generated text.
  static Future<String?> getAIResponse(String userInput, String language, {String? studentContext}) async {
    try {
      final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
      
      // Prompt engineering for mentorship context
      String languageName = (language == 'hi-IN') ? "Hindi" : (language == 'mr-IN' ? "Marathi" : "English");
      
      String systemPrompt = """You are a helpful and knowledgeable teacher named Deepak. You are mentoring a student.
      
      CRITICAL INSTRUCTIONS:
      1. ALWAYS reply in $languageName. Use perfect grammar and natural phrasing.
      2. If the user asks a general knowledge or academic question (e.g., about math, science, history), answer it accurately and concisely.
      3. Use the provided STUDENT DATA ONLY if the user asks something personal about themselves (like their name, marks, or performance).
      4. Keep answers under 3 sentences.
      """;
      
      if (studentContext != null) {
        systemPrompt += "\n\nSTUDENT DATA (Use only if relevant to the question):\n$studentContext";
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $mistralApiKey',
        },
        body: jsonEncode({
          "model": "mistral-small-latest",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userInput}
          ],
          "max_tokens": 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Mistral API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling Mistral API: $e');
      return null;
    }
  }

  /// Converts text to speech using ElevenLabs and returns the audio URL/Bytes.
  /// Note: ElevenLabs returns MPEG audio bytes.
  static Future<List<int>?> convertTextToSpeech(String text) async {
    try {
      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$elevenLabsVoiceId');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsApiKey,
        },
        body: jsonEncode({
          "text": text,
          "model_id": "eleven_multilingual_v2",
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5
          }
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('ElevenLabs API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling ElevenLabs API: $e');
      return null;
    }
  }
}
