class FacultyAnnotation {
  final String id;
  final String studentId;
  final String alertId;
  final String facultyName;
  final String facultyEmail;
  final String note;
  final DateTime timestamp;
  final DateTime createdAt;

  FacultyAnnotation({
    required this.id,
    required this.studentId,
    required this.alertId,
    required this.facultyName,
    required this.facultyEmail,
    required this.note,
    required this.timestamp,
    required this.createdAt,
  });

  factory FacultyAnnotation.fromJson(Map<String, dynamic> json) {
    return FacultyAnnotation(
      id: json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      alertId: json['alertId'] ?? '',
      facultyName: json['facultyName'] ?? 'Faculty',
      facultyEmail: json['facultyEmail'] ?? '',
      note: json['note'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
