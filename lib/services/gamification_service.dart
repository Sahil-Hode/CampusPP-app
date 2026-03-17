import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/gamification_model.dart';

class GamificationService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static Future<GamificationProfile> getProfile() async {
    final headers = await _headers();
    final url = '$_baseUrl/gamification/profile?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: headers);

    print('[GAMIFICATION] Profile status: ${response.statusCode}');
    print('[GAMIFICATION] Profile body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return GamificationProfile.fromJson(json['data']);
      }
    }
    throw Exception('Failed to load gamification profile');
  }

  static Future<List<XPTransaction>> getXPHistory({int page = 1, int limit = 20}) async {
    final headers = await _headers();
    final url = '$_baseUrl/gamification/xp-history?page=$page&limit=$limit&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        final transactions = json['data']['transactions'] as List? ?? [];
        return transactions.map((e) => XPTransaction.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load XP history');
  }

  static Future<List<GamificationBadge>> getBadges() async {
    final headers = await _headers();
    final url = '$_baseUrl/gamification/badges?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        final badges = json['data']['badges'] as List? ?? [];
        return badges.map((e) => GamificationBadge.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load badges');
  }

  static Future<LeaderboardData> getLeaderboard({int limit = 10}) async {
    final headers = await _headers();
    final url = '$_baseUrl/gamification/leaderboard?limit=$limit&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return LeaderboardData.fromJson(json['data']);
      }
    }
    throw Exception('Failed to load leaderboard');
  }

  static Future<LeaderboardData> getGlobalLeaderboard({int limit = 10}) async {
    final headers = await _headers();
    final url = '$_baseUrl/gamification/leaderboard/global?limit=$limit&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return LeaderboardData.fromJson(json['data']);
      }
    }
    throw Exception('Failed to load global leaderboard');
  }
}
