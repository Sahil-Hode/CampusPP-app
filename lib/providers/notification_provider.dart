import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentFilter = 'All'; // All | Unread | Critical | Warning | Info

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get currentFilter => _currentFilter;

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final bool isUnread = _currentFilter == 'Unread';
      final response = await NotificationService.getNotifications(
        page: _currentPage,
        limit: 20,
        unreadOnly: isUnread,
      );

      if (response.success) {
        var newNotifs = response.data;
        
        // Filter locally if severity filter is selected since backend only supports unreadOnly
        if (_currentFilter == 'Critical' || _currentFilter == 'Warning' || _currentFilter == 'Info') {
            newNotifs = newNotifs.where((n) => n.severity.toLowerCase() == _currentFilter.toLowerCase()).toList();
        }

        if (refresh) {
          _notifications = newNotifs;
        } else {
            // Avoid duplicates
            for (var notif in newNotifs) {
                if (!_notifications.any((n) => n.id == notif.id)) {
                    _notifications.add(notif);
                }
            }
        }
        
        _unreadCount = response.unreadCount;
        _currentPage++;
        _hasMore = response.pagination.page < response.pagination.totalPages;
      }
    } catch (e) {
      print('Error fetching notifications in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      // Optimistic update
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        type: _notifications[index].type,
        severity: _notifications[index].severity,
        title: _notifications[index].title,
        message: _notifications[index].message,
        action: _notifications[index].action,
        isRead: true, // Marked as read
        readAt: DateTime.now(),
        metadata: _notifications[index].metadata,
        channels: _notifications[index].channels,
        createdAt: _notifications[index].createdAt,
      );
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      final success = await NotificationService.markAsRead(id);
      if (!success) {
        // Revert on failure (complex to revert fully without refetch, but a simple refetch is fine)
        fetchNotifications(refresh: true);
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update locally
    for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
           _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            type: _notifications[i].type,
            severity: _notifications[i].severity,
            title: _notifications[i].title,
            message: _notifications[i].message,
            action: _notifications[i].action,
            isRead: true, // Marked as read
            metadata: _notifications[i].metadata,
            channels: _notifications[i].channels,
            createdAt: _notifications[i].createdAt,
          );
        }
    }
    _unreadCount = 0;
    notifyListeners();

    final success = await NotificationService.markAllAsRead();
    if (!success) {
       fetchNotifications(refresh: true);
    }
  }

  Future<void> deleteNotification(String id) async {
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      await NotificationService.deleteNotification(id);
      fetchUnreadCount();
  }

  void setFilter(String filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      fetchNotifications(refresh: true);
    }
  }
}
