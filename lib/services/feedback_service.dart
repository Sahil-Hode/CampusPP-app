import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FeedbackService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';
  static const String _lastFeedbackKey = 'last_feedback_timestamp';
  static const String _feedbackCountKey = 'feedback_session_count';

  /// Backend accepts targetType: 'learning_path', 'ar_model', 'mock_interview'
  /// 'mock_interview' doesn't validate targetId against a collection,
  /// so we use it as the universal type for general app feedback.
  static const Map<String, String> _targetTypeMap = {
    'mock_interview': 'mock_interview',
    'code_runner': 'mock_interview',
    'ai_council': 'mock_interview',
    '3d_mentor': 'mock_interview',
  };

  /// Submit user feedback to backend.
  /// Required fields: targetType, targetId, rating. Optional: comment.
  static Future<Map<String, dynamic>> submitFeedback({
    required String feature,
    required int rating,
    String? comment,
    String? targetId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    // Resolve targetType from feature key
    final targetType = _targetTypeMap[feature] ?? 'learning_path';

    // Use provided targetId or derive one from token (user's own ID)
    final resolvedTargetId = targetId ?? _extractUserIdFromToken(token);

    final body = {
      'targetType': targetType,
      'targetId': resolvedTargetId,
      'rating': rating,
      'comment': comment != null && comment.isNotEmpty
          ? '[$feature] $comment'
          : '[$feature] feedback',
    };

    print('FeedbackService: POST /feedback → $body');

    final response = await http.post(
      Uri.parse('$_baseUrl/feedback'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('FeedbackService: ${response.statusCode} → ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _recordFeedbackTimestamp();
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit feedback');
  }

  /// Extract the user's MongoDB ObjectId from the JWT payload.
  static String _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return _fallbackObjectId();
      // JWT payload is base64url encoded
      String payload = parts[1];
      // Pad to multiple of 4
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded);
      return data['id'] ?? _fallbackObjectId();
    } catch (_) {
      return _fallbackObjectId();
    }
  }

  /// Generate a deterministic fallback ObjectId from timestamp.
  static String _fallbackObjectId() {
    final hex = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toRadixString(16)
        .padLeft(8, '0');
    return '${hex}0000000000000000';
  }

  /// Determine if we should show the feedback dialog.
  /// Uses randomness + cooldown so it doesn't annoy the user.
  static Future<bool> shouldShowFeedback() async {
    final prefs = await SharedPreferences.getInstance();

    // Increment session count for this feature usage
    final count = (prefs.getInt(_feedbackCountKey) ?? 0) + 1;
    await prefs.setInt(_feedbackCountKey, count);

    // Don't show feedback on the very first usage — let user explore first
    if (count < 2) return false;

    // Cooldown: don't show more than once every 30 minutes
    final lastTimestamp = prefs.getInt(_lastFeedbackKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = 30 * 60 * 1000; // 30 minutes
    if (now - lastTimestamp < cooldownMs) return false;

    // Random chance: ~35% probability
    final random = Random();
    return random.nextDouble() < 0.35;
  }

  static Future<void> _recordFeedbackTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastFeedbackKey, DateTime.now().millisecondsSinceEpoch);
  }
}
