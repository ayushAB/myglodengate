import 'package:myglodengate/Features/Resitdent/Model/complaint.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final _client = Supabase.instance.client;

  Future<void> submitComplaint(String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('complaints').insert({
      'resident_id': userId,
      'content': content,
    });
  }

  Future<List<Complaint>> fetchMyComplaints() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final res = await _client
        .from('complaints')
        .select()
        .eq('resident_id', userId)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Complaint.fromMap(e)).toList();
  }
}
