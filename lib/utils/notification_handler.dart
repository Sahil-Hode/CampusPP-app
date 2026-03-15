import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

// This MUST be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // The notification is automatically displayed by FCM on Android
  print('Background notification: ${message.data}');
}

class NotificationHandler {
  // A global navigator key so we can navigate without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    // 1. FOREGROUND — app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final notification = message.notification;

      // Show local notification banner
      LocalNotificationService.show(
        title: notification?.title ?? 'Campus++ Alert',
        body: notification?.body ?? '',
        severity: data['severity'] ?? 'info',
        payload: jsonEncode(data),
      );
    });

    // 2. BACKGROUND — user taps notification to open app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data);
    });

    // 3. TERMINATED — app was closed, opened via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Add a slight delay to ensure Flutter has mounted the initial widget.
        Future.delayed(const Duration(milliseconds: 1500), () {
             handleNotificationTap(message.data);
        });
      }
    });
  }

  static void handleLocalNotificationTap(String payload) {
    if (payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        handleNotificationTap(data);
      } catch (e) {
        print('Error decoding local notification payload: $e');
      }
    }
  }

  static void handleNotificationTap(Map<String, dynamic> data) async {
    final actionLink = data['actionLink'] ?? '';
    final notificationId = data['notificationId'];

    // Mark as read on the backend
    if (notificationId != null) {
      await NotificationService.markAsRead(notificationId);
    }

    // Navigate based on actionLink or type
    navigateToRoute(actionLink);
  }

  static void navigateToRoute(String link) {
    if (link.isEmpty || navigatorKey.currentState == null) return;
    print('Navigating to from Push Tap: $link');

    // Remove the leading slash if present for mapping, or handle it as is
    String routeName = link;

    switch (link) {
      case '/student/performance/action-plan':
        routeName = '/action-plan';
        break;
      case '/student/performance/risk-breakdown':
        routeName = '/risk-breakdown';
        break;
      case '/student/performance/recommendations':
        routeName = '/recommendations';
        break;
      case '/student/performance/impact-simulator':
        routeName = '/impact-simulator';
        break;
      case '/student/performance/overview':
      case '/student/performance/scores':
      case '/student/performance':
        routeName = '/performance';
        break;
      case '/student/ai-council':
        routeName = '/ai-council';
        break;
      case '/student/faculty-notes':
      case '/faculty-notes':
        routeName = '/faculty-notes';
        break;
      case '/notifications':
        routeName = '/notifications';
        break;
      default:
        routeName = '/notifications';
        if (link.startsWith('/student/learning/')) {
             routeName = '/learning';
        }
        break;
    }
    
    // Attempt navigation.
    // If the Route doesn't exist, this might throw or do nothing, 
    // depending on the onGenerateRoute implementation in the app.
    navigatorKey.currentState?.pushNamed(routeName);
  }
}
