import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'pages/login_page.dart';
import 'pages/landing_page.dart';
import 'pages/dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/local_notification_service.dart';
import 'utils/notification_handler.dart';
import 'providers/notification_provider.dart';
import 'screens/notification_list_screen.dart';
import 'pages/gamification_page.dart';
import 'pages/faculty_notes_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Requires google-services.json / GoogleService-Info.plist)
  try {
     await Firebase.initializeApp();

     // Notification Handlers
     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
     await LocalNotificationService.initialize();
     await NotificationHandler.initialize();

     final messaging = FirebaseMessaging.instance;
     // Request permission (required for iOS + Android 13+)
     await messaging.requestPermission(
       alert: true,
       badge: true,
       sound: true,
       criticalAlert: true,
     );

     // Request Android local notification permission explicitly for Android 13+
     if (Platform.isAndroid) {
       final flnPlugin = FlutterLocalNotificationsPlugin();
       final androidPlugin = flnPlugin.resolvePlatformSpecificImplementation<
           AndroidFlutterLocalNotificationsPlugin>();
       await androidPlugin?.requestNotificationsPermission();
     }
     
     // Get FCM token
     final fcmToken = await messaging.getToken();
     print('FCM Token on init: $fcmToken');
     if (fcmToken != null) {
       await NotificationService.registerToken(fcmToken, Platform.isAndroid ? 'android' : 'ios');
     }

     messaging.onTokenRefresh.listen((newToken) {
       NotificationService.registerToken(newToken, Platform.isAndroid ? 'android' : 'ios');
     });
  } catch (e) {
      print('Firebase Initialization Error: $e. Did you run flutterfire configure?');
  }

  final token = await AuthService.getToken();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(isLoggedIn: token != null),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationHandler.navigatorKey, // Global key for notification routing
      title: 'Campus ++',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7DD3C0),
          primary: const Color(0xFF7DD3C0),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
          '/': (context) => const LandingPage(),
          '/dashboard': (context) => const DashboardPage(),
          // Re-map backend urls to existing ones if they exist, or fallback
          '/notifications': (context) => const NotificationListScreen(),
          '/gamification': (context) => const GamificationPage(),
          '/faculty-notes': (context) => const FacultyNotesPage(),
          // Note: you will need to map these dynamically if the pages exist. 
          // For now they will fall back gracefully due to how routes work, 
          // but we define them here in case the user has the pages ready.
      },
    );
  }
}
