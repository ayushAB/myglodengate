import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef OnSelectNotification = void Function(String? payload);

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  OnSelectNotification? _onSelect;

  void setOnSelectNotification(OnSelectNotification handler) {
    _onSelect = handler;
  }

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onSelect?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create required channels on Android (ids must stay stable)
    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'visitor_alerts',
      'Visitor Alerts',
      description: 'Notifications when a guest arrives at the gate',
      importance: Importance.high,
    );
    const AndroidNotificationChannel serviceChannel =
        AndroidNotificationChannel(
          'visitor_bg_service_silent',
          'Background Service',
          description: 'Keeps visitor alerts listening in the background',
          importance: Importance.min, // as unobtrusive as allowed
          showBadge: false,
        );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _fln
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidPlugin?.createNotificationChannel(alertsChannel);
      await androidPlugin?.createNotificationChannel(serviceChannel);
    }

    _initialized = true;
  }

  Future<void> showVisitorArrived({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'visitor_alerts',
      'Visitor Alerts',
      channelDescription: 'Notifications when a guest arrives at the gate',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'visitor',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _fln.show(
      notificationId ??
          (DateTime.now().millisecondsSinceEpoch % 100000), // simple unique id
      title,
      body,
      details,
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background tap handler; will call foreground handler once app resumes
  // We could persist payload somewhere if needed.
}
