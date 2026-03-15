import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/notification_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Get the shared preferences for redirect storage
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
            // Because the flutter local notification plugin may be handling clicks when the app is in
            // the background/terminated, it's safer to use the NotificationHandler directly
            NotificationHandler.handleLocalNotificationTap(response.payload!);
        }
      },
    );

    // Create notification channels for Android
    await _createChannels();
  }

  static Future<void> _createChannels() async {
    const criticalChannel = AndroidNotificationChannel(
      'critical_alerts',
      'Critical Alerts',
      description: 'High priority academic alerts requiring immediate action',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const warningChannel = AndroidNotificationChannel(
      'warning_alerts',
      'Warning Alerts',
      description: 'Academic warnings that need attention',
      importance: Importance.high,
    );

    const infoChannel = AndroidNotificationChannel(
      'info_alerts',
      'Information',
      description: 'General academic updates and information',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(criticalChannel);
    await androidPlugin?.createNotificationChannel(warningChannel);
    await androidPlugin?.createNotificationChannel(infoChannel);
  }

  static Future<void> show({
    required String title,
    required String body,
    required String severity,
    String? payload,
  }) async {
    final channelId = severity == 'critical'
        ? 'critical_alerts'
        : severity == 'warning'
            ? 'warning_alerts'
            : 'info_alerts';

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'critical_alerts'
              ? 'Critical Alerts'
              : channelId == 'warning_alerts'
                  ? 'Warning Alerts'
                  : 'Information',
          priority: severity == 'critical' ? Priority.max : Priority.high,
          importance: severity == 'critical' ? Importance.max : Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
