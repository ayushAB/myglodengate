import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVisitorDialog extends StatefulWidget {
  final VoidCallback onVisitorAdded;

  const AddVisitorDialog({super.key, required this.onVisitorAdded});

  @override
  State<AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends State<AddVisitorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String? _selectedFlat;
  bool _isLoading = false;
  List<String> _flats = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  Future<void> _loadFlats() async {
    final response = await Supabase.instance.client
        .from('flats')
        .select('flat_number');
    setState(() {
      _flats = List<String>.from(
        response.map((row) => row['flat_number'].toString()),
      );
    });
  }

  Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('visitors').insert({
        'name': _nameController.text.trim(),
        'flat_number': _selectedFlat,
        'purpose': _purposeController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      // 2. Fetch FCM token of the resident in selected flat
      final userRes =
          await Supabase.instance.client
              .from('users')
              .select('fcm_token')
              .eq('flat_number', _selectedFlat!)
              .maybeSingle();

      final userFcmToken = userRes?['fcm_token'];

      // 3. If token exists, send FCM alert
      if (userFcmToken != null && userFcmToken.isNotEmpty) {
        final response = await Supabase.instance.client.functions.invoke(
          'send-alert',
          body: {
            'fcm_token': userFcmToken,
            'title': 'Visitor Alert',
            'body': 'A new visitor has arrived at the gate.',
          },
        );

        if (response.status == 200) {
          debugPrint('Alert sent!');
        } else {
          debugPrint('Failed to send alert: ${response.status}');
        }
      }

      widget.onVisitorAdded();

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error adding visitor: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add visitor")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Visitor"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Visitor Name"),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFlat,
                items:
                    _flats
                        .map(
                          (flat) =>
                              DropdownMenuItem(value: flat, child: Text(flat)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedFlat = value),
                decoration: const InputDecoration(labelText: "Flat Number"),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: "Purpose"),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitVisitor,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Add"),
        ),
      ],
    );
  }
}
