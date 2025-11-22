import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorApprovalScreen extends StatefulWidget {
  final String id;
  const VisitorApprovalScreen({super.key, required this.id});

  @override
  State<VisitorApprovalScreen> createState() => _VisitorApprovalScreenState();
}

class _VisitorApprovalScreenState extends State<VisitorApprovalScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res =
        await Supabase.instance.client
            .from('visitors')
            .select()
            .eq('id', widget.id)
            .maybeSingle();
    if (mounted)
      setState(() {
        data = res;
        loading = false;
      });
  }

  Future<void> _act(String status) async {
    setState(() => acting = true);
    try {
      print(status);
      await Supabase.instance.client
          .from('visitors')
          .update({'status': status})
          .eq('id', widget.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor approval')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Text(
                              (data?['name'] ?? data?['visitor_name'] ?? 'G')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data?['name'] ??
                                          data?['visitor_name'] ??
                                          'Guest')
                                      .toString(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Purpose: ' +
                                      (data?['purpose']?.toString() ?? '—'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Flat: ' +
                                      (data?['flat_number']?.toString() ?? '—'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Approve',
                              icon: Icons.check_circle_outline,
                              loading: acting,
                              onPressed: acting ? null : () => _act('approved'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: acting ? null : () => _act('rejected'),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
