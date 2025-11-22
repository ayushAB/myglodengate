import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens for visitor status changes (approved/rejected) and
/// notifies guard users locally.
class GuardAlertProvider with ChangeNotifier {
  RealtimeChannel? _approvedCh;
  RealtimeChannel? _rejectedCh;

  Future<void> startListening() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Check role; only enable for security/guard
    final roleRow =
        await supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();
    final role = roleRow?['role']?.toString();
    if (role == null || role.toLowerCase() != 'security') {
      return;
    }

    await NotificationService().init();

    _approvedCh =
        supabase
            .channel('guard-alerts-approved')
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

    _rejectedCh =
        supabase
            .channel('guard-alerts-rejected')
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
  }

  @override
  void dispose() {
    _approvedCh?.unsubscribe();
    _rejectedCh?.unsubscribe();
    super.dispose();
  }
}
