enum RiskLevel {
  safe,
  warning,
  critical,
}

enum StabilityStatus {
  stable,
  unstable,
}

class Student {
  final String name;
  final RiskLevel riskLevel;
  final StabilityStatus stability;

  Student({
    required this.name,
    required this.riskLevel,
    required this.stability,
  });

  String get riskLevelText {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.warning:
        return 'Warning';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  String get stabilityText {
    switch (stability) {
      case StabilityStatus.stable:
        return 'Stable';
      case StabilityStatus.unstable:
        return 'Unstable';
    }
  }
}

class AttendanceData {
  final double percentage;
  final String rating;

  AttendanceData({
    required this.percentage,
    required this.rating,
  });
}

class LMSEngagement {
  final bool isActive;
  final String lastLogin;
  final String activityLevel; // Low, Medium, High

  LMSEngagement({
    required this.isActive,
    required this.lastLogin,
    required this.activityLevel,
  });

  String get statusText => isActive ? 'Active' : 'Inactive';
}

class SubjectMark {
  final String subject;
  final double marks;
  final double maxMarks;

  SubjectMark({
    required this.subject,
    required this.marks,
    this.maxMarks = 100,
  });

  double get percentage => (marks / maxMarks) * 100;
}

// Sample data for demonstration
class DashboardData {
  static Student getSampleStudent() {
    return Student(
      name: 'Alex Johnson',
      riskLevel: RiskLevel.safe,
      stability: StabilityStatus.stable,
    );
  }

  static AttendanceData getSampleAttendance() {
    return AttendanceData(
      percentage: 88.0,
      rating: 'Excellent',
    );
  }

  static LMSEngagement getSampleLMSEngagement() {
    return LMSEngagement(
      isActive: true,
      lastLogin: '2h ago',
      activityLevel: 'High',
    );
  }

  static List<SubjectMark> getSampleSubjectMarks() {
    return [
      SubjectMark(subject: 'Math', marks: 92),
      SubjectMark(subject: 'Science', marks: 85),
      SubjectMark(subject: 'English', marks: 78),
      SubjectMark(subject: 'Art', marks: 95),
    ];
  }
}
