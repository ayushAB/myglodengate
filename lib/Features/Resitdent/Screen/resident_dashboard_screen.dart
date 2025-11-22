import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  String? userFlatNo;
  String? displayName;
  String? avatarUrl;
  int pendingVisitors = 0;
  int approvedVisitors = 0;
  int rejectedVisitors = 0;
  int todaysVisitors = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserFlatNo();
  }

  Future<void> fetchUserFlatNo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      final response =
          await Supabase.instance.client
              .from('users')
              .select('flat_number, name, email, flat_number')
              .eq('id', userId)
              .maybeSingle();

      if (response != null && mounted) {
        userFlatNo = response['flat_number']?.toString();
        displayName = (response['full_name'] as String?)?.trim();
        avatarUrl = response['avatar_url'] as String?;
        displayName ??= (response['email'] as String?)?.split('@').first;
        await _fetchPendingVisitors();
        if (mounted) setState(() => loading = false);
        listenToNewVisitors();
      }
    }
  }

  void listenToNewVisitors() {
    Supabase.instance.client
        .from('visitors')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((List<Map<String, dynamic>> visitors) {
          for (final visitor in visitors) {
            if (visitor['flat_number']?.toString() == userFlatNo) {
              // Only update counters; rely on local notification for alerts
              _fetchPendingVisitors();
            }
          }
        });
  }

  void showVisitorAlert(String visitorName) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('New Visitor'),
            content: Text('$visitorName has been added for your flat.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _fetchPendingVisitors() async {
    if (userFlatNo == null) return;
    final res = await Supabase.instance.client
        .from('visitors')
        .select('status, created_at')
        .eq('flat_number', userFlatNo!);

    int pending = 0;
    int approved = 0;
    int rejected = 0;
    int today = 0;
    final now = DateTime.now();

    for (final record in res as List) {
      final status = (record['status'] ?? '').toString().toLowerCase();
      final createdAtRaw = record['created_at'];
      DateTime? createdAt;
      if (createdAtRaw is DateTime) {
        createdAt = createdAtRaw;
      } else if (createdAtRaw != null) {
        createdAt = DateTime.tryParse(createdAtRaw.toString());
      }
      if (createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        today += 1;
      }

      switch (status) {
        case 'pending':
          pending += 1;
          break;
        case 'approved':
          approved += 1;
          break;
        case 'rejected':
          rejected += 1;
          break;
      }
    }

    if (mounted) {
      setState(() {
        pendingVisitors = pending;
        approvedVisitors = approved;
        rejectedVisitors = rejected;
        todaysVisitors = today;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleWidget = Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
          child:
              (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Text(
                    (displayName?.isNotEmpty == true
                            ? displayName!.substring(0, 1)
                            : 'U')
                        .toUpperCase(),
                  )
                  : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName ?? 'Resident',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              userFlatNo != null ? 'Flat $userFlatNo' : 'Fetching flat…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );

    return GradientScaffold(
      appBar: GradientAppBar(
        title: 'Resident Dashboard',
        titleWidget: titleWidget,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeroCard(
                      displayName: displayName ?? 'Resident',
                      flatNumber: userFlatNo ?? '—',
                      pendingVisitors: pendingVisitors,
                      onViewVisitors: () => context.push('/resident/visitors'),
                      onReportIssue: () => context.push('/resident/complaint'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MetricStrip(
                      metrics: [
                        _MetricData(
                          label: 'Pending',
                          value: pendingVisitors,
                          color: Colors.orange,
                          icon: Icons.pending_actions_outlined,
                        ),
                        _MetricData(
                          label: 'Approved',
                          value: approvedVisitors,
                          color: Colors.green,
                          icon: Icons.verified_outlined,
                        ),
                        _MetricData(
                          label: 'Rejected',
                          value: rejectedVisitors,
                          color: Colors.redAccent,
                          icon: Icons.cancel_outlined,
                        ),
                        _MetricData(
                          label: "Today's",
                          value: todaysVisitors,
                          color: Colors.teal,
                          icon: Icons.today_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QuickActionsGrid(
                      actions: [
                        _QuickAction(
                          icon: Icons.qr_code_2_outlined,
                          title: 'Visitor pass',
                          subtitle: 'Share instant QR',
                          color: Colors.indigo,
                          onTap: () => context.push('/resident/visitors'),
                        ),
                        _QuickAction(
                          icon: Icons.credit_card_outlined,
                          title: 'Maintenance',
                          subtitle: 'Pay dues',
                          color: Colors.pinkAccent,
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.report_problem_outlined,
                          title: 'Raise issue',
                          subtitle: 'Notify society',
                          color: Colors.deepOrange,
                          onTap: () => context.push('/resident/complaint'),
                        ),
                        _QuickAction(
                          icon: Icons.person_outline,
                          title: 'My profile',
                          subtitle: 'Household info',
                          color: Colors.teal,
                          onTap: () => context.push('/resident/profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _VisitorsPreviewCard(theme: theme, flatNumber: userFlatNo),
                    const SizedBox(height: AppSpacing.lg),
                    _ServicesCard(
                      onPayments: () {},
                      onHistory: () {},
                      onDirectory: () {},
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CommunityUpdatesCard(),
                  ],
                ),
              ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  final String displayName;
  final String flatNumber;
  final int pendingVisitors;
  final VoidCallback onViewVisitors;
  final VoidCallback onReportIssue;

  const _DashboardHeroCard({
    required this.displayName,
    required this.flatNumber,
    required this.pendingVisitors,
    required this.onViewVisitors,
    required this.onReportIssue,
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
          colors: [Color(0xFF5E5CEA), Color(0xFF7F8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $displayName',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Flat $flatNumber',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Colors.white70),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  pendingVisitors > 0
                      ? 'You have $pendingVisitors visitor requests awaiting action.'
                      : 'No pending visitor approvals right now.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewVisitors,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: const Text('Manage visitors'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5E5CEA),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReportIssue,
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  label: const Text('Report issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  final List<_MetricData> metrics;
  const _MetricStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            metrics
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: _MetricCard(data: item),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _MetricData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: data.color.withOpacity(0.15),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            data.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600;
    final maxWidth = isCompact ? double.infinity : (width / 2) - AppSpacing.lg;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children:
          actions
              .map(
                (action) => SizedBox(
                  width: maxWidth,
                  child: _QuickActionTile(action: action),
                ),
              )
              .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: const BorderRadius.all(AppRadii.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: action.color.withOpacity(0.12),
              child: Icon(action.icon, color: action.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    action.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class _VisitorsPreviewCard extends StatelessWidget {
  final ThemeData theme;
  final String? flatNumber;

  const _VisitorsPreviewCard({required this.theme, required this.flatNumber});

  @override
  Widget build(BuildContext context) {
    final stream =
        flatNumber == null
            ? null
            : Supabase.instance.client
                .from('visitors')
                .stream(primaryKey: ['id'])
                .eq('flat_number', flatNumber!)
                .order('created_at', ascending: false)
                .limit(5);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recent visitors',
            actionLabel: 'View all',
            onAction: () => context.push('/resident/visitors'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (flatNumber == null)
            const _EmptyPlaceholder(
              message: 'Link your flat to start tracking visitors.',
            )
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                final visitors = snapshot.data ?? const [];
                if (visitors.isEmpty) {
                  return const _EmptyPlaceholder(
                    message: 'No visitor logs yet. Guards will add them here.',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visitors.length,
                  separatorBuilder:
                      (_, __) => const Divider(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    return _VisitorPreviewTile(visitor: visitor);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VisitorPreviewTile extends StatelessWidget {
  final Map<String, dynamic> visitor;
  const _VisitorPreviewTile({required this.visitor});

  String _formatTime(dynamic raw) {
    if (raw == null) return '—';
    final dt = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • Today';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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

  @override
  Widget build(BuildContext context) {
    final name =
        ((visitor['name'] ?? visitor['visitor_name']) ?? 'Guest').toString();
    final purpose = visitor['purpose']?.toString() ?? 'Purpose not added';
    final status = visitor['status']?.toString().toLowerCase() ?? 'pending';
    final createdAt = visitor['created_at'];

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.08),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G'),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                purpose,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: const BorderRadius.all(AppRadii.md),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: _statusColor(status)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatTime(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _ServicesCard extends StatelessWidget {
  final VoidCallback onPayments;
  final VoidCallback onHistory;
  final VoidCallback onDirectory;

  const _ServicesCard({
    required this.onPayments,
    required this.onHistory,
    required this.onDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Society services'),
          const SizedBox(height: AppSpacing.sm),
          _ServiceTile(
            icon: Icons.credit_card_outlined,
            title: 'Pay maintenance',
            subtitle: 'Secure Razorpay checkout',
            onTap: onPayments,
          ),
          const Divider(),
          _ServiceTile(
            icon: Icons.receipt_long_outlined,
            title: 'Payment history',
            subtitle: 'Download receipts anytime',
            onTap: onHistory,
          ),
          const Divider(),
          _ServiceTile(
            icon: Icons.handshake_outlined,
            title: 'Society directory',
            subtitle: 'Office, maintenance, security contacts',
            onTap: onDirectory,
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.08),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CommunityUpdatesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final updates = [
      'Deep cleaning for Block B this Friday at 11 AM.',
      'Gym maintenance scheduled for 24 Nov, 2-4 PM.',
      'Please renew vehicle stickers before 30 Nov.',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Community updates'),
          const SizedBox(height: AppSpacing.sm),
          ...updates.map(
            (text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_outlined, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
