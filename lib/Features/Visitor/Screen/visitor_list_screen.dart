import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : visitors.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                  itemCount: visitors.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    final v = visitors[i];
                    return AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.12),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  v.purpose,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (v.status == 'pending') ...[
                            IconButton(
                              tooltip: 'Approve',
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => updateVisitorStatus(v.id, 'approved'),
                            ),
                            IconButton(
                              tooltip: 'Reject',
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => updateVisitorStatus(v.id, 'rejected'),
                            ),
                          ] else
                            Chip(
                              label: Text(v.status.toUpperCase()),
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No visitors yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'New visitor requests will appear here.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
