class StudentProfile {
  final String name;
  final String email;
  final String studentId;
  final String language;
  final String avatarUrl;
  final String instituteName;
  final String classes;
  final String course;
  final String? resumeText;
  final String? resumeUploadedAt;
  final String phoneNo;
  final String instituteId;
  final String? dateOfJoin;
  
  StudentProfile({
    required this.name,
    required this.email,
    required this.studentId,
    required this.language,
    required this.avatarUrl,
    required this.instituteName,
    required this.classes,
    required this.course,
    required this.phoneNo,
    required this.instituteId,
    this.dateOfJoin,
    this.resumeText,
    this.resumeUploadedAt,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      studentId: json['studentId'] ?? '',
      language: json['language'] ?? 'English',
      // Using 'avatar' key if it exists, otherwise default. API doesn't mention it but UI uses it.
      avatarUrl: json['profilePhoto'] ??
          json['avatar'] ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
      instituteName: json['instituteName'] ?? '',
      classes: json['classes'] ?? '',
      course: json['Course'] ?? '', 
      phoneNo: json['phoneNo'] ?? '',
      instituteId: json['instituteId'] ?? '',
      dateOfJoin: json['dateOfJoin']?.toString(),
      resumeText: json['resumeText'],
      resumeUploadedAt: json['resumeUploadedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'language': language,
      'classes': classes,
      'Course': course,
      'phoneNo': phoneNo,
    };
  }
}
