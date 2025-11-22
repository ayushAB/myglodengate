// Android-only foreground service to keep Supabase Realtime alive
// and show local notifications when a guest arrives, even if the app is closed.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:myglodengate/Core/Constants/supabase_config.dart';
import 'package:myglodengate/Core/Services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _serviceChannelId = 'visitor_bg_service_silent';

RealtimeChannel? _bgChannel;
RealtimeChannel? _bgGuardApprovedCh;
RealtimeChannel? _bgGuardRejectedCh;

Future<void> initializeVisitorBackgroundService() async {
  if (!kIsWeb && Platform.isAndroid) {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: visitorServiceOnStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: _serviceChannelId,
        initialNotificationTitle: 'My Golden Gate',
        initialNotificationContent: 'Listening for visitor alerts…',
        foregroundServiceNotificationId: 7771,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }
}

Future<void> startVisitorBackgroundService() async {
  if (!kIsWeb && Platform.isAndroid) {
    await FlutterBackgroundService().startService();
  }
}

@pragma('vm:entry-point')
void visitorServiceOnStart(ServiceInstance service) async {
  // Required for plugin channels in background isolate
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Init Supabase and notifications in this isolate
  try {
    if (Supabase.instance.client.auth.currentUser == null) {
      // Initialize Supabase if not yet available in this isolate
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    }
  } catch (_) {
    // Initialize if calling instance failed
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  await NotificationService().init();

  // Set up the realtime listener
  final supabase = Supabase.instance.client;

  // Retrieve current user id; if not logged in, do nothing but keep service alive
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    // Periodically check if user logs in later
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (supabase.auth.currentUser?.id != null) {
        timer.cancel();
        _startRealtimeSubscription(supabase);
        await _maybeStartGuardSubscriptions(supabase);
      }
    });
  } else {
    _startRealtimeSubscription(supabase);
    await _maybeStartGuardSubscriptions(supabase);
  }

  // Optional: handle stop command
  service.on('stop').listen((event) {
    _bgChannel?.unsubscribe();
    _bgGuardApprovedCh?.unsubscribe();
    _bgGuardRejectedCh?.unsubscribe();
    service.stopSelf();
  });
}

void _startRealtimeSubscription(SupabaseClient supabase) {
  _bgChannel?.unsubscribe();
  _bgChannel =
      supabase
          .channel('visitor-alerts-bg')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'visitors',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'status',
              value: 'pending',
            ),
            callback: (payload) async {
              final data = payload.newRecord;
              final String? visitorFlat = data['flat_number'];
              final approvedBy = data['approved_by'];
              final String? visitorName = data['name'] ?? data['visitor_name'];

              // Get current user's flat
              final userId = supabase.auth.currentUser?.id;
              if (userId == null) return;

              final userResponse =
                  await supabase
                      .from('users')
                      .select('flat_number')
                      .eq('id', userId)
                      .single();

              final String? userFlat = userResponse['flat_number'];

              if (visitorFlat != null &&
                  userFlat != null &&
                  visitorFlat.toString() == userFlat.toString() &&
                  approvedBy == null) {
                final title = 'Guest has arrived';
                final body =
                    visitorName != null
                        ? '$visitorName is at the gate for Flat $userFlat'
                        : 'A guest is at the gate for Flat $userFlat';

                await NotificationService().showVisitorArrived(
                  title: title,
                  body: body,
                  payload: 'visitor_pending',
                  notificationId:
                      (data['id'] is int) ? data['id'] as int : null,
                );
              }
            },
          )
          .subscribe();
}

Future<void> _maybeStartGuardSubscriptions(SupabaseClient supabase) async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final roleRow =
        await supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();
    final role = roleRow?['role']?.toString().toLowerCase();
    if (role != 'security') return;

    // Approved updates
    _bgGuardApprovedCh =
        supabase
            .channel('bg-guard-approved')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'visitors',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'status',
                value: 'approved',
              ),
              callback: (payload) async {
                final data = payload.newRecord;
                final name = data['name'] ?? data['visitor_name'] ?? 'Guest';
                final flat = data['flat_number']?.toString() ?? '-';
                await NotificationService().showVisitorArrived(
                  title: 'Request approved',
                  body: '$name approved for Flat $flat',
                  notificationId:
                      (data['id'] is int) ? data['id'] as int : null,
                );
              },
            )
            .subscribe();

    // Rejected updates
    _bgGuardRejectedCh =
        supabase
            .channel('bg-guard-rejected')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'visitors',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'status',
                value: 'rejected',
              ),
              callback: (payload) async {
                final data = payload.newRecord;
                final name = data['name'] ?? data['visitor_name'] ?? 'Guest';
                final flat = data['flat_number']?.toString() ?? '-';
                await NotificationService().showVisitorArrived(
                  title: 'Request rejected',
                  body: '$name rejected for Flat $flat',
                  notificationId:
                      (data['id'] is int) ? data['id'] as int : null,
                );
              },
            )
            .subscribe();
  } catch (_) {}
}
