import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final res = await client.from('users').select().eq('id', user.id).single();

    return res;
  }
}
