import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Guard/Screen/add_visitor_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuardVisitorsScreen extends StatefulWidget {
  const GuardVisitorsScreen({super.key});

  @override
  State<GuardVisitorsScreen> createState() => _GuardVisitorsScreenState();
}

class _GuardVisitorsScreenState extends State<GuardVisitorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';

  final Map<String, String> _statusLabels = const {
    'all': 'All',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guardName =
        Supabase.instance.client.auth.currentUser?.email?.split('@').first ??
        'Guard';
    return GradientScaffold(
      appBar: GradientAppBar(
        title: "Visitor History",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/guard/dashboard'),
        ),
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
            print("Visitors count: ${visitors.length}");
            if (visitors.isEmpty) {
              return _EmptyState(theme: theme);
            }

            final pendingCount = _countByStatus(visitors, 'pending');
            final approvedCount = _countByStatus(visitors, 'approved');
            final rejectedCount = _countByStatus(visitors, 'rejected');
            final todayCount =
                visitors.where((v) => _isSameDay(v['created_at'])).length;
            final uniqueFlats =
                visitors
                    .map((v) => v['flat_number']?.toString())
                    .whereType<String>()
                    .toSet()
                    .length;
            final statusCounts = {
              'all': visitors.length,
              'pending': pendingCount,
              'approved': approvedCount,
              'rejected': rejectedCount,
            };

            final filtered =
                visitors.where((visitor) {
                  final status = _statusOf(visitor);
                  final name =
                      ((visitor['name'] ?? visitor['visitor_name']) ?? '')
                          .toString()
                          .toLowerCase();
                  final flat =
                      visitor['flat_number']?.toString().toLowerCase() ?? '';

                  final matchesStatus =
                      _statusFilter == 'all' || status == _statusFilter;
                  final matchesSearch =
                      _searchTerm.isEmpty ||
                      name.contains(_searchTerm) ||
                      flat.contains(_searchTerm);
                  return matchesStatus && matchesSearch;
                }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _SummaryRow(
                        total: visitors.length,
                        pending: pendingCount,
                        approved: approvedCount,
                        rejected: rejectedCount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged:
                                  (value) => setState(
                                    () =>
                                        _searchTerm =
                                            value.trim().toLowerCase(),
                                  ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'Search visitor or flat number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    _statusLabels.entries.map((entry) {
                                      final value = entry.key;
                                      final label = entry.value;
                                      final selected = _statusFilter == value;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.sm,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            '$label (${statusCounts[value] ?? 0})',
                                          ),
                                          selected: selected,
                                          onSelected:
                                              (_) => setState(
                                                () => _statusFilter = value,
                                              ),
                                          selectedColor: theme
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                          labelStyle: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    selected
                                                        ? theme
                                                            .colorScheme
                                                            .primary
                                                        : theme
                                                            .colorScheme
                                                            .onSurface,
                                              ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                  AppRadii.md,
                                                ),
                                            side: BorderSide(
                                              color:
                                                  selected
                                                      ? theme
                                                          .colorScheme
                                                          .primary
                                                      : theme
                                                          .colorScheme
                                                          .outline
                                                          .withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(theme: theme),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final visitor = filtered[index];
                      return _VisitorTile(visitor: visitor, theme: theme);
                    }, childCount: filtered.length),
                  ),
              ],
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

  Future<void> _openAddVisitorDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AddVisitorDialog(onVisitorAdded: () {}),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VisitorTile extends StatelessWidget {
  final Map<String, dynamic> visitor;
  final ThemeData theme;

  const _VisitorTile({required this.visitor, required this.theme});

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

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '—';
    final parsed = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
    if (parsed == null) return '—';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  Widget _buildInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: const BorderRadius.all(AppRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        ((visitor['name'] ?? visitor['visitor_name']) ?? 'Guest').toString();
    final flat = visitor['flat_number']?.toString() ?? '-';
    final purpose = visitor['purpose']?.toString();
    final status = visitor['status']?.toString().toLowerCase() ?? 'pending';
    final createdAt = visitor['created_at'];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Created ${_formatTimestamp(createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildInfoPill(Icons.apartment, 'Flat $flat'),
              _buildInfoPill(Icons.schedule, _formatTimestamp(createdAt)),
            ],
          ),
          if (purpose != null && purpose.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(purpose, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _SummaryRow({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      _SummaryTile(
        label: 'Total',
        value: total,
        color: theme.colorScheme.primary,
      ),
      _SummaryTile(label: 'Pending', value: pending, color: Colors.orange),
      _SummaryTile(label: 'Approved', value: approved, color: Colors.green),
      _SummaryTile(label: 'Rejected', value: rejected, color: Colors.red),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tiles
                .map(
                  (tile) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: SizedBox(width: 170, child: tile),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      margin: EdgeInsets.zero,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardHeroCard extends StatelessWidget {
  final int pending;
  final int today;
  final int uniqueFlats;
  final String guardName;

  const _GuardHeroCard({
    required this.guardName,
    required this.pending,
    required this.today,
    required this.uniqueFlats,
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
          colors: [Color(0xFF1D2B64), Color(0xFF1FA2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gate control',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Welcome back, $guardName',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HeroStat(label: 'Pending approvals', value: pending.toString()),
              const SizedBox(width: AppSpacing.lg),
              _HeroStat(label: 'Arrivals today', value: today.toString()),
              const SizedBox(width: AppSpacing.lg),
              _HeroStat(label: 'Unique flats', value: uniqueFlats.toString()),
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
              fontWeight: FontWeight.bold,
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

class _GuardQuickActions extends StatelessWidget {
  final VoidCallback onScanQr;
  final VoidCallback onLogManual;
  final VoidCallback onAlertResident;

  const _GuardQuickActions({
    required this.onScanQr,
    required this.onLogManual,
    required this.onAlertResident,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner,
        label: 'Scan visitor QR',
        subtitle: 'Approve faster',
        onTap: onScanQr,
      ),
      _QuickAction(
        icon: Icons.edit_note_outlined,
        label: 'Manual entry',
        subtitle: 'Add visitor details',
        onTap: onLogManual,
      ),
      _QuickAction(
        icon: Icons.notifications_active_outlined,
        label: 'Notify resident',
        subtitle: 'Send quick alert',
        onTap: onAlertResident,
      ),
    ];

    final isCompact = MediaQuery.of(context).size.width < 640;
    final maxWidth =
        isCompact
            ? double.infinity
            : (MediaQuery.of(context).size.width / 3) - AppSpacing.lg;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
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

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.onTap,
      borderRadius: const BorderRadius.all(AppRadii.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(action.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.label, style: theme.textTheme.titleMedium),
                  Text(
                    action.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 42, color: theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.sm),
          Text('Nothing to show yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New visitors will appear here instantly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
