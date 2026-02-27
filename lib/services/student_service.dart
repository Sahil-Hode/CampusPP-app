import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/performance_model.dart';
import '../models/student_profile_model.dart';
import 'package:http_parser/http_parser.dart';

class StudentService {
  static const String _baseUrl = 'https://campuspp-f7qx.onrender.com/api';

  static Future<PerformanceData> getPerformance() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Performance: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Get Performance Status: ${response.statusCode}');
    print('Get Performance Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null && json['data']['currentPerformance'] != null) {
        return PerformanceData.fromJson(json['data']['currentPerformance']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load performance data');
    }
  }

  static Future<RiskData> getRiskStatus() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance/risk?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Risk: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Risk Response: ${response.body}');
      if (json['success'] == true && json['data'] != null) {
        return RiskData.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load risk status');
    }
  }


  static Future<ScoreBreakdown> getScoreBreakdown() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance/scores?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Scores: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Get Scores Status: ${response.statusCode}');
    print('Get Scores Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return ScoreBreakdown.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load score breakdown');
    }
  }

  static Future<TrendsData> getTrends() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance/trends?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return TrendsData.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load trends');
    }
  }

  static Future<RecommendationsData> getRecommendations() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance/recommendations?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return RecommendationsData.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  static Future<OverviewData> getOverview() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Overview: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Overview Response: ${response.body}');
      if (json['success'] == true && json['data'] != null) {
         var perf = json['data']['currentPerformance'] ?? {};
         return OverviewData.fromJson(perf);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load overview');
    }
  }

  static Future<List<LearningPath>> getLearningPaths() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/learning?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url), 
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((item) => LearningPath.fromJson(item))
            .toList();
      } else {
        return []; // Return empty list if no data
      }
    } else {
      throw Exception('Failed to load learning paths');
    }
  }
  
  static Future<LearningPath> generateLearningPath(String topic) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$_baseUrl/learning/generate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'topic': topic}),
    );

    print('Generate Path Response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return LearningPath.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to generate path: ${response.statusCode} ${response.body}');
    }
  }

  static Future<InterventionData> getIntervention() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/performance/intervention?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Intervention: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Get Intervention Status: ${response.statusCode}');
    print('Get Intervention Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return InterventionData.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load intervention data');
    }
  }

  static Future<StudentProfile> getProfile() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/profile?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Profile: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Get Profile Status: ${response.statusCode}');
    print('Get Profile Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Assuming response structure { status: success, data: { ... } } or just { ... }
      // User didn't specify GET response structure, assuming standard wrapping or direct
      // Based on Resume API, likely wrapped in 'data'
      if (json['data'] != null) {
        return StudentProfile.fromJson(json['data']);
      } else {
        return StudentProfile.fromJson(json);
      }
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<StudentProfile> getFullStudentProfile() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/full-data?t=${DateTime.now().millisecondsSinceEpoch}';
    print('Fetching Full Student Data: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Get Full Student Data Status: ${response.statusCode}');
    print('Get Full Student Data Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['data'] != null && json['data']['profile'] != null) {
        return StudentProfile.fromJson(json['data']['profile']);
      } else if (json['profile'] != null) {
        return StudentProfile.fromJson(json['profile']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load full student data');
    }
  }

  static Future<void> updateProfile(String name, String language, String classes) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$_baseUrl/student/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'language': language,
        'classes': classes,
      }),
    );

    print('Update Profile Status: ${response.statusCode}');
    print('Update Profile Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/student/profile/photo'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    final extension = filePath.toLowerCase().split('.').last;
    MediaType contentType;
    if (extension == 'png') {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('image', 'jpeg');
    }

    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      filePath,
      contentType: contentType,
    ));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    print('Upload Photo Status: ${response.statusCode}');
    print('Upload Photo Body: $responseBody');
    
    if (response.statusCode != 200) {
      if (responseBody.contains('<!DOCTYPE html>')) {
        throw Exception('Server Error (404/500). Please check the API configuration.');
      }
      try {
        final errData = jsonDecode(responseBody);
        throw Exception(errData['message'] ?? 'Failed to upload photo');
      } catch (e) {
        throw Exception('Failed to upload photo (Status ${response.statusCode})');
      }
    }

    final data = jsonDecode(responseBody);
    return data['data'];
  }

  static Future<Map<String, dynamic>> uploadResume(String filePath) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    // Ensure the URL is correct - matching the GET structure
    final url = '$_baseUrl/student/profile/resume';
    print('DEBUG: Calling Upload Resume URL: $url');
    
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Detect MIME type properly
    final extension = filePath.toLowerCase().split('.').last;
    MediaType contentType;
    if (extension == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (extension == 'docx') {
      contentType = MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
    } else {
      contentType = MediaType('application', 'msword');
    }

    request.files.add(await http.MultipartFile.fromPath(
      'resume', 
      filePath,
      contentType: contentType,
    ));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('DEBUG: Upload Resume Status: ${response.statusCode}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.body.contains('<!DOCTYPE html>')) {
          if (response.statusCode == 404) {
            throw Exception('API Endpoint Not Found (404). Please verify the server path.');
          } else {
            throw Exception('Server Internal Error (500). The server crashed while processing the file.');
          }
        }
        
        try {
          final errData = jsonDecode(response.body);
          throw Exception(errData['message'] ?? 'Failed to upload resume (Status ${response.statusCode})');
        } catch (e) {
          throw Exception('Server Error: ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? {};
      } else {
        throw Exception(data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('DEBUG: Upload Catch: $e');
      rethrow;
    }
  }
  static Future<LearningPath> getLearningPath(String id) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/learning/$id?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
       final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return LearningPath.fromJson(json['data']);
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load learning path details');
    }
  }

  static Future<void> updateLearningProgress(String learningPathId, int completedSteps) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$_baseUrl/learning/$learningPathId/progress'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'completedSteps': completedSteps}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update progress');
    }
  }

  static Future<Map<String, dynamic>> fetchFullStudentData() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final url = '$_baseUrl/student/full-data?t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Fetch Full Data Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data'];
      } else {
        throw Exception('Invalid data structure');
      }
    } else {
      throw Exception('Failed to load full student data');
    }
  }
  static Future<void> deleteLearningPath(String id) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$_baseUrl/learning/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete learning path: ${response.body}');
    }
  }
}
