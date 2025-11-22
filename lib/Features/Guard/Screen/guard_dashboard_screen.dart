import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Guard/Screen/add_visitor_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuardDashboardScreen extends StatefulWidget {
  const GuardDashboardScreen({super.key});

  @override
  State<GuardDashboardScreen> createState() => _GuardDashboardScreenState();
}

class _GuardDashboardScreenState extends State<GuardDashboardScreen> {
  Future<void> _openAddVisitorDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AddVisitorDialog(onVisitorAdded: () {}),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final guardName =
        user?.email != null ? user!.email!.split('@').first : 'Guard';
    return GradientScaffold(
      appBar: GradientAppBar(title: "Guard Dashboard"),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVisitorDialog(),
        label: const Text('Add Visitor'),
        icon: const Icon(
          Icons.person_add,
        ), // Optional: remove if you want *only* text
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('visitors')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final visitors = snapshot.data ?? <Map<String, dynamic>>[];
            final pendingCount = _countByStatus(visitors, 'pending');
            final approvedCount = _countByStatus(visitors, 'approved');
            final rejectedCount = _countByStatus(visitors, 'rejected');
            final todayArrivals =
                visitors.where((v) => _isSameDay(v['created_at'])).length;
            final uniqueFlats =
                visitors
                    .map((v) => v['flat_number']?.toString())
                    .whereType<String>()
                    .toSet()
                    .length;
            final recentVisitors = visitors.take(5).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuardDashboardHero(
                    guardName: guardName,
                    pending: pendingCount,
                    today: todayArrivals,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _GuardMetricGrid(
                    metrics: [
                      _MetricCardData(
                        label: 'Pending',
                        value: pendingCount,
                        icon: Icons.timer_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      _MetricCardData(
                        label: 'Approved',
                        value: approvedCount,
                        icon: Icons.verified_outlined,
                        color: Colors.green,
                      ),
                      _MetricCardData(
                        label: 'Rejected',
                        value: rejectedCount,
                        icon: Icons.block_outlined,
                        color: Colors.red,
                      ),
                      _MetricCardData(
                        label: 'Unique flats',
                        value: uniqueFlats,
                        icon: Icons.apartment_outlined,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _GuardDashboardActions(
                    onAddVisitor: _openAddVisitorDialog,
                    onViewPending: () => context.go('/guard/pending-visitors'),
                    onViewAll: () => context.go('/guard/visitors'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RecentVisitorsSection(visitors: recentVisitors),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _countByStatus(List<Map<String, dynamic>> visitors, String status) {
    return visitors.where((v) => _statusOf(v) == status).length;
  }

  String _statusOf(Map<String, dynamic> visitor) {
    return visitor['status']?.toString().trim().toLowerCase() ?? '';
  }

  bool _isSameDay(dynamic rawDate) {
    final parsed = _parseDate(rawDate);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate == null) return null;
    if (rawDate is DateTime) return rawDate;
    return DateTime.tryParse(rawDate.toString());
  }
}

class _GuardDashboardHero extends StatelessWidget {
  final String guardName;
  final int pending;
  final int today;

  const _GuardDashboardHero({
    required this.guardName,
    required this.pending,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $guardName',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gate security overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _HeroStat(label: 'Pending approvals', value: pending.toString()),
              const SizedBox(width: AppSpacing.lg),
              _HeroStat(label: 'Arrivals today', value: today.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GuardMetricGrid extends StatelessWidget {
  final List<_MetricCardData> metrics;

  const _GuardMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            metrics.map((metric) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: SizedBox(
                  width: 190,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: metric.color.withOpacity(0.12),
                          child: Icon(metric.icon, color: metric.color),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${metric.value}',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: metric.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          metric.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _GuardDashboardActions extends StatelessWidget {
  final VoidCallback onAddVisitor;
  final VoidCallback onViewPending;
  final VoidCallback onViewAll;

  const _GuardDashboardActions({
    required this.onAddVisitor,
    required this.onViewPending,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _DashboardActionData(
        icon: Icons.qr_code_scanner,
        title: 'Scan & admit',
        subtitle: 'Open QR scanner',
        onTap: onAddVisitor,
      ),
      _DashboardActionData(
        icon: Icons.fact_check_outlined,
        title: 'Pending queue',
        subtitle: 'Review waiting visitors',
        onTap: onViewPending,
      ),
      _DashboardActionData(
        icon: Icons.history,
        title: 'Visitor history',
        subtitle: 'Browse all records',
        onTap: onViewAll,
      ),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children:
          actions
              .map(
                (action) => SizedBox(
                  width: 260,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(AppRadii.lg),
                    onTap: action.onTap,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(action.icon),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  action.subtitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _DashboardActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _RecentVisitorsSection extends StatelessWidget {
  final List<Map<String, dynamic>> visitors;

  const _RecentVisitorsSection({required this.visitors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/guard/visitors'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (visitors.isEmpty)
            Text(
              'No visitors logged yet today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visitors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _RecentVisitorTile(visitor: visitors[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _RecentVisitorTile extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const _RecentVisitorTile({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        ((visitor['name'] ?? visitor['visitor_name']) ?? 'Guest').toString();
    final flat = visitor['flat_number']?.toString() ?? '-';
    final status =
        visitor['status']?.toString().trim().toLowerCase() ?? 'pending';
    final createdAt = visitor['created_at'];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name, style: theme.textTheme.titleMedium),
      subtitle: Text(
        'Flat $flat · ${_formatTime(createdAt)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.12),
          borderRadius: const BorderRadius.all(AppRadii.md),
        ),
        child: Text(
          _statusLabel(status),
          style: theme.textTheme.labelMedium?.copyWith(
            color: _statusColor(status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '—';
    final parsed = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
    if (parsed == null) return '—';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}
