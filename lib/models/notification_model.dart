class NotificationModel {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final NotificationAction? action;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;
  final NotificationChannels channels;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.action,
    required this.isRead,
    this.readAt,
    required this.metadata,
    required this.channels,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'general',
      severity: json['severity'] ?? 'info',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      action: json['action'] != null ? NotificationAction.fromJson(json['action']) : null,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      metadata: json['metadata'] ?? {},
      channels: NotificationChannels.fromJson(json['channels'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class NotificationAction {
  final String? text;
  final String? link;

  NotificationAction({this.text, this.link});

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      text: json['text'],
      link: json['link'],
    );
  }
}

class NotificationChannels {
  final ChannelStatus push;
  final ChannelStatus email;
  final ChannelStatus inApp;

  NotificationChannels({
    required this.push,
    required this.email,
    required this.inApp,
  });

  factory NotificationChannels.fromJson(Map<String, dynamic> json) {
    return NotificationChannels(
      push: ChannelStatus.fromJson(json['push'] ?? {}),
      email: ChannelStatus.fromJson(json['email'] ?? {}),
      inApp: ChannelStatus.fromJson(json['inApp'] ?? {}),
    );
  }
}

class ChannelStatus {
  final bool sent;
  final DateTime? sentAt;

  ChannelStatus({required this.sent, this.sentAt});

  factory ChannelStatus.fromJson(Map<String, dynamic> json) {
    return ChannelStatus(
      sent: json['sent'] ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
    );
  }
}

class NotificationListResponse {
  final bool success;
  final List<NotificationModel> data;
  final NotificationPagination pagination;
  final int unreadCount;

  NotificationListResponse({
    required this.success,
    required this.data,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> jsonList = json['data'] ?? [];
    return NotificationListResponse(
      success: json['success'] ?? false,
      data: jsonList.map((j) => NotificationModel.fromJson(j)).toList(),
      pagination: NotificationPagination.fromJson(json['pagination'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
