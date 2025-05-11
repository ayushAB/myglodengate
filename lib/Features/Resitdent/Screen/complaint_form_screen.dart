import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Resitdent/Services/complaint_service.dart';
import 'package:myglodengate/Features/Resitdent/Widget/resident_drawer.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _controller = TextEditingController();
  final _service = ComplaintService();
  bool _loading = false;

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.submitComplaint(content);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: GradientAppBar(title: 'Submit '),
      drawer: const ResidentDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter your complaint',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
