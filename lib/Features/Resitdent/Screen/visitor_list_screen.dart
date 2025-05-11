import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Resitdent/Widget/resident_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorListScreen extends StatelessWidget {
  const VisitorListScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchVisitors() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      print('Fetching visitors for user: $userId');

      final response = await Supabase.instance.client
          .from('visitors')
          .select()
          .eq('approved_by', userId);
      print(response);
      return response;
    } on PostgrestException catch (e) {
      print('Postgrest error: ${e.message}');
      throw Exception('Failed to fetch visitors: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred while fetching visitors.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: GradientAppBar(title: 'My Visitors'),
      drawer: const ResidentDrawer(),
      body: FutureBuilder(
        future: _fetchVisitors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final visitors = snapshot.data!;
          return ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return ListTile(
                title: Text(visitor['name']),
                subtitle: Text("Time: ${visitor['time']}"),
              );
            },
          );
        },
      ),
    );
  }
}
