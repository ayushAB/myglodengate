import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Visitor/Model/visitor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  List<Visitor> visitors = [];
  bool loading = true;

  Future<void> fetchVisitors() async {
    print("called");
    final response = await Supabase.instance.client
        .from('visitors')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      visitors = response.map<Visitor>((v) => Visitor.fromMap(v)).toList();
      loading = false;
    });
  }

  Future<void> updateVisitorStatus(String id, String status) async {
    await Supabase.instance.client
        .from('visitors')
        .update({'status': status})
        .eq('id', id);
    fetchVisitors();
  }

  @override
  void initState() {
    super.initState();
    fetchVisitors();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: GradientAppBar(title: 'Visitor Approval'),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: visitors.length,
                itemBuilder: (_, i) {
                  final v = visitors[i];
                  return ListTile(
                    title: Text(v.name),
                    subtitle: Text(v.purpose),
                    trailing:
                        v.status == 'pending'
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () =>
                                          updateVisitorStatus(v.id, 'approved'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () =>
                                          updateVisitorStatus(v.id, 'rejected'),
                                ),
                              ],
                            )
                            : Text(v.status),
                  );
                },
              ),
    );
  }
}
