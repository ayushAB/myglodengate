import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myglodengate/App/app_router.dart';
import 'package:myglodengate/Core/Constants/supabase_config.dart';
import 'package:myglodengate/Core/Theme/Theme.dart';
import 'package:myglodengate/Core/Services/notification_service.dart';
import 'package:myglodengate/Core/Utils/visitor_alert_initializer.dart';
import 'package:myglodengate/Core/Services/visitor_background_service.dart';
import 'package:myglodengate/Providers/visitor_alert_provider.dart';
import 'package:myglodengate/Providers/guard_alert_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // You can show a local notification here if needed
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await Firebase.initializeApp();

  // Background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications used for visitor alerts
  await NotificationService().init();
  NotificationService().setOnSelectNotification((payload) {
    if (payload == null) return;
    try {
      final map = Map<String, dynamic>.from(
        (payload.startsWith('{')) ? (jsonDecode(payload) as Map) : {},
      );
      final type = map['type'] as String?;
      final id = map['id']?.toString();
      if (type == 'visitor_pending' && id != null) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          GoRouter.of(ctx).push('/resident/visitor/$id');
        }
      }
    } catch (_) {}
  });

  // Start Android background service to keep realtime alive when app is closed
  if (!kIsWeb && Platform.isAndroid) {
    await initializeVisitorBackgroundService();
    await startVisitorBackgroundService();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VisitorAlertProvider()),
        ChangeNotifierProvider(create: (_) => GuardAlertProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions
    NotificationSettings settings = await messaging.requestPermission();
    print('FCM permission granted: ${settings.authorizationStatus}');

    // Get the token
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    // You can store this token in Supabase if needed

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.notification?.title}');
      // Show a custom in-app alert or navigate
    });

    // When the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Opened from FCM: ${message.notification?.title}');
      // You can auto-navigate to specific screens here
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Golden Gate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return VisitorAlertInitializer(child: child!);
      },
    );
  }
}
