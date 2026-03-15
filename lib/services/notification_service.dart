import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl = 'https://campuspp-f7qx.onrender.com/api/notifications';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Register FCM token
  static Future<bool> registerToken(String fcmToken, String platform) async {
    final headers = await _headers();
    if (!headers.containsKey('Authorization') || headers['Authorization'] == 'Bearer null') {
      return false; // Not logged in
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register-token'),
        headers: headers,
        body: jsonEncode({'token': fcmToken, 'platform': platform}),
      );
      print('Register Token Res: ${res.statusCode} ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('Error registering token: $e');
      return false;
    }
  }

  // Unregister FCM token (call on logout)
  static Future<bool> unregisterToken(String fcmToken) async {
    final headers = await _headers();
    if (!headers.containsKey('Authorization') || headers['Authorization'] == 'Bearer null') {
      return false;
    }

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/unregister-token'),
        headers: headers,
        body: jsonEncode({'token': fcmToken}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error unregistering token: $e');
      return false;
    }
  }

  // Get paginated notifications
  static Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final headers = await _headers();
      final uri = Uri.parse('$baseUrl?page=$page&limit=$limit&unreadOnly=$unreadOnly');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return NotificationListResponse.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error loading notifications: $e');
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse('$baseUrl/unread-count'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark single as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = await _headers();
      final res = await http.patch(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // Mark all as read
  static Future<bool> markAllAsRead() async {
    try {
      final headers = await _headers();
      final res = await http.patch(Uri.parse('$baseUrl/read-all'), headers: headers);
      return res.statusCode == 200;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  // Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _headers();
      final res = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Trigger guardian scan (For Testing/Admin)
  static Future<Map<String, dynamic>> triggerScan() async {
    try {
      final headers = await _headers();
      final res = await http.post(Uri.parse('$baseUrl/trigger-scan'), headers: headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Send manual notification (For Testing/Admin)
  // When type is 'faculty_annotation', also saves to the facultyannotations collection
  static Future<bool> sendManual({
    required String title,
    required String message,
    String type = 'general',
    String severity = 'info',
  }) async {
    try {
      final headers = await _headers();
      final res = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'message': message,
          'type': type,
          'severity': severity,
        }),
      );

      // Also save to facultyannotations collection if it's a faculty note
      if (type == 'faculty_annotation') {
        _saveFacultyAnnotation(headers, title, message);
      }

      return res.statusCode == 200;
    } catch (e) {
      print('Error sending manual notification: $e');
      return false;
    }
  }

  // Save to facultyannotations collection (best-effort, non-blocking)
  static Future<void> _saveFacultyAnnotation(
    Map<String, String> headers,
    String title,
    String note,
  ) async {
    try {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '') ?? '';
      final studentId = _extractStudentIdFromToken(token);
      if (studentId.isEmpty) return;

      await http.post(
        Uri.parse('https://campuspp-f7qx.onrender.com/api/faculty-annotations'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'note': note,
          'alertId': title,
        }),
      );
    } catch (_) {
      // Best-effort — don't block the main notification flow
    }
  }

  // Extract studentId from JWT token
  static String _extractStudentIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded);
      return data['studentId'] ?? '';
    } catch (_) {
      return '';
    }
  }
}
