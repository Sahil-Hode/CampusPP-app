import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_handler.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays == 1) {
      return '1d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'low_marks':
      case 'low_subject':
        return Icons.bar_chart;
      case 'low_attendance':
        return Icons.calendar_today;
      case 'high_risk':
        return Icons.warning_amber_rounded;
      case 'declining_trend':
        return Icons.trending_down;
      case 'quiz_failure':
        return Icons.cancel_outlined;
      case 'quiz_cooldown_complete':
        return Icons.timer;
      case 'overdue_module':
      case 'missed_module':
      case 'learning_path_pending':
        return Icons.menu_book;
      case 'lms_low':
      case 'assignment_low':
        return Icons.assignment;
      case 'career_mismatch':
        return Icons.work_outline;
      case 'low_confidence':
        return Icons.psychology;
      case 'smart_alert':
      case 'faculty_annotation':
        return Icons.notifications_active;
      case 'general':
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getSeverityColor() {
    switch (notification.severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFFCDD2);
      case 'warning':
        return const Color(0xFFFFD54F);
      case 'info':
      default:
        return const Color(0xFFC5CAE9);
    }
  }

  Color _getIconBgColor() {
    switch (notification.severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF8B94);
      case 'warning':
        return const Color(0xFFFFC857);
      case 'info':
      default:
        return const Color(0xFF7986CB);
    }
  }

  String _getSeverityLabel() {
    switch (notification.severity.toLowerCase()) {
      case 'critical':
        return 'CRITICAL';
      case 'warning':
        return 'WARNING';
      case 'info':
      default:
        return 'INFO';
    }
  }

  Widget _buildSubjectBreakdown() {
    if (notification.type == 'low_subject' &&
        notification.metadata.containsKey('subjects')) {
      try {
        List<dynamic> subjects = notification.metadata['subjects'];
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: subjects.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s['subject']}: ${s['marks']}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
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
    final cardColor = isUnread ? _getSeverityColor() : Colors.white;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8B94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.black, size: 24),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
          if (notification.action?.link != null &&
              notification.action!.link!.isNotEmpty) {
            NotificationHandler.navigateToRoute(notification.action!.link!);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getIconBgColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Severity Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getSeverityLabel(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF8B94),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                _timeAgo(notification.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Message Body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  notification.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

              // Subject Breakdown (for low_subject type)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildSubjectBreakdown(),
              ),

              // Action Button
              if (notification.action != null &&
                  notification.action!.text != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: GestureDetector(
                    onTap: () {
                      if (isUnread) {
                        context
                            .read<NotificationProvider>()
                            .markAsRead(notification.id);
                      }
                      NotificationHandler.navigateToRoute(
                          notification.action!.link ?? '');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.action!.text!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
