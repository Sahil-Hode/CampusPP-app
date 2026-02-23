class Interviewer {
  final String id;
  final String name;
  final String role;
  final String gender;

  Interviewer({
    required this.id,
    required this.name,
    required this.role,
    required this.gender,
  });

  factory Interviewer.fromJson(Map<String, dynamic> json) {
    return Interviewer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      gender: json['gender'] ?? '',
    );
  }
}

class InterviewSession {
  final String sessionId;
  final Interviewer interviewer;
  final String openingMessage;
  final Map<String, dynamic> voiceConfig;

  InterviewSession({
    required this.sessionId,
    required this.interviewer,
    required this.openingMessage,
    required this.voiceConfig,
  });

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      sessionId: json['sessionId'] ?? '',
      interviewer: Interviewer.fromJson(json['interviewer'] ?? {}),
      openingMessage: json['openingMessage'] ?? '',
      voiceConfig: json['voiceConfig'] ?? {},
    );
  }
}

class InterviewResponse {
  final Interviewer interviewer;
  final String message;
  final int questionCount;
  final Map<String, dynamic>? voiceConfig;

  InterviewResponse({
    required this.interviewer,
    required this.message,
    required this.questionCount,
    this.voiceConfig,
  });

  factory InterviewResponse.fromJson(Map<String, dynamic> json) {
    return InterviewResponse(
      interviewer: Interviewer.fromJson(json['interviewer'] ?? {}),
      message: json['message'] ?? '',
      questionCount: json['questionCount'] ?? 0,
      voiceConfig: json['voiceConfig'],
    );
  }
}

class InterviewFeedback {
  final String sessionId;
  final String status;
  final Map<String, dynamic> feedback;
  final int questionCount;
  final int duration;

  InterviewFeedback({
    required this.sessionId,
    required this.status,
    required this.feedback,
    required this.questionCount,
    required this.duration,
  });

  factory InterviewFeedback.fromJson(Map<String, dynamic> json) {
    return InterviewFeedback(
      sessionId: json['sessionId'] ?? '',
      status: json['status'] ?? '',
      feedback: json['feedback'] ?? {},
      questionCount: json['questionCount'] ?? 0,
      duration: json['duration'] ?? 0,
    );
  }
}
