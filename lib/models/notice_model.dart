class Notice {
  final String id;
  final String title;
  final String message;
  final String type;       // e.g. "bulk", "individual"
  final String priority;   // "high" | "medium" | "low"
  final String status;     // "active" | "expired"
  final DateTime createdAt;
  final DateTime? expiresAt;

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id:        json['_id']      ?? json['id']       ?? '',
      title:     json['title']    ?? json['subject']  ?? 'Notice',
      message:   json['message']  ?? json['body']     ?? json['content'] ?? '',
      type:      json['type']     ?? 'bulk',
      priority:  json['priority'] ?? json['severity'] ?? 'medium',
      status:    json['status']   ?? 'active',
      createdAt: _parseDate(json['createdAt'] ?? json['sentAt']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
