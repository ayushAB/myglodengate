import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  bool loading = false;

  Future<void> submitComplaint() async {
    setState(() => loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('complaints').insert({
      'user_id': user.id,
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
    });

    setState(() => loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
    titleCtrl.clear();
    descCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submitComplaint,
              child:
                  loading
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
