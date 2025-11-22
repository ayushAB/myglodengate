import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Resitdent/Widget/resident_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';
  Future<String>? _flatNumberFuture;
  final Set<String> _processingVisitorIds = <String>{};

  final Map<String, String> _statusLabels = const {
    'all': 'All',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _flatNumberFuture = _fetchFlatNumber();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _fetchFlatNumber() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Please sign in again.');
    }

    final profile =
        await Supabase.instance.client
            .from('users')
            .select('flat_number')
            .eq('id', userId)
            .single();

    final flatNumber = profile['flat_number'];
    if (flatNumber == null) {
      throw Exception('No flat linked to this account.');
    }

    return flatNumber.toString();
  }

  Stream<List<Map<String, dynamic>>> _visitorStream(String flatNumber) {
    return Supabase.instance.client
        .from('visitors')
        .stream(primaryKey: ['id'])
        .eq('flat_number', flatNumber)
        .order('created_at', ascending: false);
  }

  Future<void> _updateVisitorStatus(String visitorId, String status) async {
    setState(() {
      _processingVisitorIds.add(visitorId);
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final decisionBy =
          user?.userMetadata?['full_name'] ?? user?.email ?? 'Resident';

      await Supabase.instance.client
          .from('visitors')
          .update({'status': status, 'approved_by': decisionBy})
          .eq('id', visitorId);

      if (!mounted) return;
      final message =
          status == 'approved' ? 'Visitor approved.' : 'Visitor rejected.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update visitor: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _processingVisitorIds.remove(visitorId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: GradientAppBar(title: 'My Visitors'),
      drawer: const ResidentDrawer(),
      body:
          _flatNumberFuture == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<String>(
                future: _flatNumberFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    );
                  }

                  final flatNumber = snapshot.data;
                  if (flatNumber == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visitor history',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Every gate entry for Flat $flatNumber, updated in real time.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _searchController,
                          onChanged:
                              (value) => setState(
                                () => _searchTerm = value.trim().toLowerCase(),
                              ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search visitor or purpose',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.3,
                                ),
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
                                      label: Text(label),
                                      selected: selected,
                                      onSelected:
                                          (_) => setState(
                                            () => _statusFilter = value,
                                          ),
                                      selectedColor: theme.colorScheme.primary
                                          .withOpacity(0.15),
                                      labelStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                selected
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                        .colorScheme
                                                        .onSurface,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: const BorderRadius.all(
                                          AppRadii.md,
                                        ),
                                        side: BorderSide(
                                          color:
                                              selected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.outline
                                                      .withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _visitorStream(flatNumber),
                            builder: (context, visitorSnapshot) {
                              if (visitorSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !visitorSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final visitors = visitorSnapshot.data ?? const [];
                              if (visitors.isEmpty) {
                                return _ResidentEmptyState(theme: theme);
                              }

                              final filtered =
                                  visitors.where((visitor) {
                                    final status =
                                        visitor['status']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    final name =
                                        ((visitor['name'] ??
                                                    visitor['visitor_name']) ??
                                                '')
                                            .toString()
                                            .toLowerCase();
                                    final purpose =
                                        visitor['purpose']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';

                                    final matchesStatus =
                                        _statusFilter == 'all' ||
                                        status == _statusFilter;
                                    final matchesSearch =
                                        _searchTerm.isEmpty ||
                                        name.contains(_searchTerm) ||
                                        purpose.contains(_searchTerm);
                                    return matchesStatus && matchesSearch;
                                  }).toList();

                              final pendingCount =
                                  visitors
                                      .where(
                                        (v) =>
                                            (v['status']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '') ==
                                            'pending',
                                      )
                                      .length;
                              final approvedCount =
                                  visitors
                                      .where(
                                        (v) =>
                                            (v['status']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '') ==
                                            'approved',
                                      )
                                      .length;
                              final rejectedCount =
                                  visitors
                                      .where(
                                        (v) =>
                                            (v['status']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '') ==
                                            'rejected',
                                      )
                                      .length;

                              return Column(
                                children: [
                                  _ResidentSummaryRow(
                                    total: visitors.length,
                                    pending: pendingCount,
                                    approved: approvedCount,
                                    rejected: rejectedCount,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Expanded(
                                    child:
                                        filtered.isEmpty
                                            ? _ResidentEmptyState(theme: theme)
                                            : ListView.builder(
                                              itemCount: filtered.length,
                                              itemBuilder: (context, index) {
                                                final visitor = filtered[index];
                                                final visitorId =
                                                    visitor['id']?.toString() ??
                                                    '';
                                                final isProcessing =
                                                    _processingVisitorIds
                                                        .contains(visitorId);
                                                final status =
                                                    visitor['status']
                                                        ?.toString()
                                                        .toLowerCase() ??
                                                    'pending';
                                                return _ResidentVisitorCard(
                                                  visitor: visitor,
                                                  theme: theme,
                                                  isProcessing: isProcessing,
                                                  onApprove:
                                                      status == 'pending' &&
                                                              visitorId
                                                                  .isNotEmpty
                                                          ? () =>
                                                              _updateVisitorStatus(
                                                                visitorId,
                                                                'approved',
                                                              )
                                                          : null,
                                                  onReject:
                                                      status == 'pending' &&
                                                              visitorId
                                                                  .isNotEmpty
                                                          ? () =>
                                                              _updateVisitorStatus(
                                                                visitorId,
                                                                'rejected',
                                                              )
                                                          : null,
                                                );
                                              },
                                            ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class _ResidentVisitorCard extends StatelessWidget {
  final Map<String, dynamic> visitor;
  final ThemeData theme;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;

  const _ResidentVisitorCard({
    required this.visitor,
    required this.theme,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
  });

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

  @override
  Widget build(BuildContext context) {
    final name =
        ((visitor['name'] ?? visitor['visitor_name']) ?? 'Guest').toString();
    final purpose = visitor['purpose']?.toString() ?? '—';
    final status = visitor['status']?.toString().toLowerCase() ?? 'pending';
    final createdAt = visitor['created_at'];
    final approvedBy = visitor['approved_by'];
    final showActions =
        status == 'pending' && (onApprove != null || onReject != null);
    final decisionLabel = status == 'rejected' ? 'Rejected by' : 'Approved by';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
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
                      'Logged ${_formatTimestamp(createdAt)}',
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
          Text(purpose, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatTimestamp(createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (approvedBy != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$decisionLabel $approvedBy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isProcessing ? null : onApprove,
                    icon:
                        isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResidentSummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _ResidentSummaryRow({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      _ResidentSummaryTile(
        label: 'Total',
        value: total,
        color: theme.colorScheme.primary,
      ),
      _ResidentSummaryTile(
        label: 'Pending',
        value: pending,
        color: Colors.orange,
      ),
      _ResidentSummaryTile(
        label: 'Approved',
        value: approved,
        color: Colors.green,
      ),
      _ResidentSummaryTile(
        label: 'Rejected',
        value: rejected,
        color: Colors.red,
      ),
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

class _ResidentSummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ResidentSummaryTile({
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

class _ResidentEmptyState extends StatelessWidget {
  final ThemeData theme;

  const _ResidentEmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 44, color: theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.sm),
          Text('No visitors yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Visitor history for your flat will appear here instantly.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
