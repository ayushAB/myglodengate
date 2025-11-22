import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class GuardPendingVisitorsScreen extends StatefulWidget {
  const GuardPendingVisitorsScreen({super.key});

  @override
  State<GuardPendingVisitorsScreen> createState() =>
      _GuardPendingVisitorsScreen();
}

class _GuardPendingVisitorsScreen extends State<GuardPendingVisitorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: GradientAppBar(
        title: "Pending Visitors",
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/guard/dashboard'),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('visitors')
            .stream(primaryKey: ['id'])
            .eq('status', 'pending')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final visitors = snapshot.data ?? const [];
          if (visitors.isEmpty) {
            return _EmptyState(theme: theme);
          }

          final filtered =
              visitors.where((visitor) {
                final name =
                    ((visitor['name'] ?? visitor['visitor_name']) ?? '')
                        .toString()
                        .toLowerCase();
                final flat =
                    visitor['flat_number']?.toString().toLowerCase() ?? '';
                if (_searchTerm.isEmpty) return true;
                return name.contains(_searchTerm) || flat.contains(_searchTerm);
              }).toList();

          final todayCount =
              visitors.where((v) => _isSameDay(v['created_at'])).length;
          final uniqueFlats =
              visitors
                  .map((v) => v['flat_number']?.toString())
                  .whereType<String>()
                  .toSet()
                  .length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _PendingHeroCard(
                      pendingCount: visitors.length,
                      todayArrivals: todayCount,
                      uniqueFlats: uniqueFlats,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _PendingSummaryRow(
                      total: visitors.length,
                      today: todayCount,
                      uniqueFlats: uniqueFlats,
                    ),
                    const SizedBox(height: AppSpacing.xs),
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
                                      _searchTerm = value.trim().toLowerCase(),
                                ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search by visitor or flat',
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
                          Text(
                            'Showing ${filtered.length} pending visitor(s)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                    return _PendingVisitorTile(visitor: visitor);
                  }, childCount: filtered.length),
                ),
            ],
          );
        },
      ),
    );
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

class _PendingHeroCard extends StatelessWidget {
  final int pendingCount;
  final int todayArrivals;
  final int uniqueFlats;

  const _PendingHeroCard({
    required this.pendingCount,
    required this.todayArrivals,
    required this.uniqueFlats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
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
              'Pending approvals',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$pendingCount visitors awaiting action',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _HeroStat(
                  label: 'Arrivals today',
                  value: todayArrivals.toString(),
                ),
                const SizedBox(width: AppSpacing.lg),
                _HeroStat(label: 'Unique flats', value: uniqueFlats.toString()),
              ],
            ),
          ],
        ),
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

class _PendingSummaryRow extends StatelessWidget {
  final int total;
  final int today;
  final int uniqueFlats;

  const _PendingSummaryRow({
    required this.total,
    required this.today,
    required this.uniqueFlats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = [
      _SummaryTileData(
        label: 'In queue',
        value: total,
        icon: Icons.timer_outlined,
        color: theme.colorScheme.primary,
      ),
      _SummaryTileData(
        label: 'Arrived today',
        value: today,
        icon: Icons.today_outlined,
        color: Colors.orange,
      ),
      _SummaryTileData(
        label: 'Unique flats',
        value: uniqueFlats,
        icon: Icons.apartment_outlined,
        color: theme.colorScheme.secondary,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((metric) => _SummaryTile(data: metric)).toList(),
      ),
    );
  }
}

class _SummaryTileData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryTile extends StatelessWidget {
  final _SummaryTileData data;
  const _SummaryTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: data.color.withOpacity(0.12),
              child: Icon(data.icon, color: data.color),
            ),
            Text(
              '${data.value}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: data.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PendingVisitorTile extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const _PendingVisitorTile({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        ((visitor['name'] ?? visitor['visitor_name']) ?? 'Guest').toString();
    final flat = visitor['flat_number']?.toString() ?? '-';
    final purpose = visitor['purpose']?.toString() ?? '—';
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
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
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
                      'Waiting ${_formatTimestamp(createdAt)}',
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
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: const BorderRadius.all(AppRadii.md),
                ),
                child: Text(
                  'Pending'.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
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
              _InfoPill(icon: Icons.apartment, label: 'Flat $flat'),
              _InfoPill(
                icon: Icons.schedule,
                label: _formatTimestamp(createdAt),
              ),
              _InfoPill(
                icon: Icons.badge_outlined,
                label: visitor['visitor_type'] ?? 'Visitor',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(purpose, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
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
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
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
          Icon(
            Icons.task_alt_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No pending visitors', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New requests will appear here in real time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
