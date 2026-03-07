import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';

class VRMockInterviewService {
  static const _mistralApiKey = 'UdA4yBd7cpW3HbQ0EPa6y8DX9pDBJcys';
  static const _sarvamApiKey = 'sk_cy9lcdh9_H8d2OtLgNoXExA9zaFhZsoWZ';
  
  // Chat History
  final List<Map<String, String>> _messages = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  VRMockInterviewService() {
    _messages.add({
      'role': 'system',
      'content': 'You are a professional technical interviewer conducting a Mock Interview. Keep your questions and responses very concise (1-2 sentences). Ask one question at a time. Do not provide code blocks or lengthy formatting. Converse naturally.'
    });
  }

  void addSystemProfile(String name, String resumeData) {
    _messages.add({
      'role': 'system',
      'content': 'The candidate name is $name. Here is their resume data context: $resumeData. Ask a relevant introductory question.'
    });
  }

  void addUserMessage(String text) {
    _messages.add({'role': 'user', 'content': text});
  }

  Future<String> getAiResponse() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mistral.ai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_mistralApiKey',
        },
        body: jsonEncode({
          'model': 'mistral-small-latest',
          'messages': _messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];
        _messages.add({'role': 'assistant', 'content': aiText});
        return aiText;
      } else {
        print('Mistral Error: ${response.statusCode} - ${response.body}');
        return "I'm sorry, I'm having trouble processing that right now.";
      }
    } catch (e) {
      print('Mistral Exception: $e');
      return "Connection error.";
    }
  }

  Future<void> speakSarvam(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.sarvam.ai/text-to-speech'),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': _sarvamApiKey,
        },
        body: jsonEncode({
          'inputs': [text],
          'target_language_code': 'en-IN',
          'speaker': 'meera',
          'pitch': 0,
          'pace': 1.1,
          'loudness': 1.5,
          'speech_sample_rate': 16000,
          'enable_preprocessing': true,
          'model': 'aurora-tts'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audios = data['audios'] as List<dynamic>;
        if (audios.isNotEmpty) {
          final String base64Audio = audios[0].toString();
          final Uint8List bytes = base64Decode(base64Audio);
          await _audioPlayer.play(BytesSource(bytes));
        }
      } else {
        print('Sarvam TTS Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Sarvam Exception: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
