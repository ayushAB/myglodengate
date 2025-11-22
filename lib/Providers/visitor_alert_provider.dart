import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorAlertProvider with ChangeNotifier {
  RealtimeChannel? _channel;

  void startListening(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    // Subscribe to visitors table
    _channel =
        supabase
            .channel('visitor-alerts')
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
                final String? visitorName =
                    data['name'] ?? data['visitor_name'];

                // Get user's flat number
                final userResponse =
                    await supabase
                        .from('users')
                        .select('flat_number')
                        .eq('id', userId)
                        .single();

                final String? userFlat = userResponse['flat_number'];

                // If the pending visitor is for the current user's flat,
                // show a local notification (works foreground/background).
                if (visitorFlat != null &&
                    userFlat != null &&
                    visitorFlat.toString() == userFlat.toString() &&
                    approvedBy == null) {
                  // Ensure notifications are initialized
                  await NotificationService().init();

                  final title = 'Guest has arrived';
                  final body =
                      visitorName != null
                          ? '$visitorName is at the gate for Flat $userFlat'
                          : 'A guest is at the gate for Flat $userFlat';

                  final idStr =
                      (data['id'] != null) ? data['id'].toString() : null;
                  final payload =
                      idStr != null
                          ? '{"type":"visitor_pending","id":"$idStr"}'
                          : '{"type":"visitor_pending"}';

                  await NotificationService().showVisitorArrived(
                    title: title,
                    body: body,
                    payload: payload,
                    notificationId:
                        (data['id'] is int) ? data['id'] as int : null,
                  );
                }
              },
            )
            .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
