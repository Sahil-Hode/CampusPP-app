import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_handler.dart';
import 'severity_indicator.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays == 1) {
      return '1 day ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'low_marks':
      case 'low_subject':
        return Icons.bar_chart; // 📊 grades icon
      case 'low_attendance':
        return Icons.calendar_today; // 📅 calendar icon
      case 'high_risk':
        return Icons.warning_amber_rounded; // ⚠️ warning icon
      case 'declining_trend':
        return Icons.trending_down; // 📉 trending down icon
      case 'quiz_failure':
        return Icons.cancel_outlined; // ❌ quiz icon
      case 'overdue_module':
      case 'missed_module':
      case 'learning_path_pending':
        return Icons.menu_book; // 📚 book icon
      case 'lms_low':
      case 'assignment_low':
        return Icons.assignment; // 📝 assignment icon
      case 'smart_alert':
      case 'faculty_annotation':
        return Icons.notifications_active; // 🔔 bell icon
      case 'general':
      default:
        return Icons.chat_bubble_outline; // 💬 message icon
    }
  }

  Widget _buildSubjectBreakdown() {
     if (notification.type == 'low_subject' && notification.metadata.containsKey('subjects')) {
        try {
            List<dynamic> subjects = notification.metadata['subjects'];
            String text = subjects.map((s) => '${s['subject']}: ${s['marks']}%').join(' | ');
            
            Widget recommendation = const SizedBox.shrink();
            if (notification.metadata.containsKey('recommendation')) {
                final rec = notification.metadata['recommendation'];
                if (rec != null && rec['recommendation'] != null) {
                    recommendation = Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            'AI Suggestion: ${rec['recommendation']}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                        )
                    );
                }
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      recommendation,
                  ],
              )
            );
        } catch (e) {
            return const SizedBox.shrink();
        }
     }
     return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
         context.read<NotificationProvider>().deleteNotification(notification.id);
      },
      child: Material(
        color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
        child: InkWell(
          onTap: () {
            if (isUnread) {
              context.read<NotificationProvider>().markAsRead(notification.id);
            }
            if (notification.action?.link != null && notification.action!.link!.isNotEmpty) {
                 NotificationHandler.navigateToRoute(notification.action!.link!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Area
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      child: Icon(_getIcon(), color: Colors.black87),
                    ),
                    if (isUnread)
                       Positioned(
                          right: 0,
                          top: 0,
                          child: SeverityIndicator(severity: notification.severity),
                       ),
                    if (!isUnread)
                       Positioned(
                          right: 0,
                          top: 0,
                          child: SeverityIndicator(severity: notification.severity, size: 8),
                       )
                  ],
                ),
                const SizedBox(width: 16),
                // Content Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                      ),
                      _buildSubjectBreakdown(),
                      if (notification.action != null && notification.action!.text != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                               if (isUnread) context.read<NotificationProvider>().markAsRead(notification.id);
                               NotificationHandler.navigateToRoute(notification.action!.link ?? '');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notification.action!.text!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
