class FacultyResource {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String fileUrl;
  final String downloadUrl;
  final String resourceType;
  final String mimeType;
  final String originalFileName;
  final int fileSizeBytes;
  final String fileSizeLabel;
  final String facultyName;
  final String instituteId;
  final DateTime createdAt;

  FacultyResource({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.fileUrl,
    required this.downloadUrl,
    required this.resourceType,
    required this.mimeType,
    required this.originalFileName,
    required this.fileSizeBytes,
    required this.fileSizeLabel,
    required this.facultyName,
    required this.instituteId,
    required this.createdAt,
  });

  factory FacultyResource.fromJson(Map<String, dynamic> json) {
    return FacultyResource(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      resourceType: json['resourceType'] ?? '',
      mimeType: json['mimeType'] ?? '',
      originalFileName: json['originalFileName'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      fileSizeLabel: json['fileSizeLabel'] ?? '',
      facultyName: json['facultyName'] ?? '',
      instituteId: json['instituteId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
