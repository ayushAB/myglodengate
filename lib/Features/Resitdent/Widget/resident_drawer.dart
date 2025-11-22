import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/Gradients.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentDrawer extends StatelessWidget {
  const ResidentDrawer({super.key});

  Future<Map<String, dynamic>> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    final response =
        await Supabase.instance.client
            .from('users')
            .select('full_name, flat_number, email, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

    final rawName = (response?['full_name'] as String?)?.trim();
    final fullName =
        (rawName != null && rawName.isNotEmpty)
            ? rawName
            : (user.email ?? 'Resident');

    return {
      'name': fullName,
      'flat': response?['flat_number']?.toString() ?? '- -',
      'email': response?['email'] ?? user.email ?? '',
      'avatar': response?['avatar_url'] as String?,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navItems = <_DrawerDestination>[
      const _DrawerDestination(
        icon: Icons.space_dashboard_outlined,
        label: 'Dashboard',
        route: '/resident/dashboard',
      ),
      const _DrawerDestination(
        icon: Icons.person_outline,
        label: 'Profile',
        route: '/resident/profile',
      ),
      const _DrawerDestination(
        icon: Icons.how_to_reg_outlined,
        label: 'Visitors',
        route: '/resident/visitors',
      ),
      const _DrawerDestination(
        icon: Icons.report_problem_outlined,
        label: 'File complaint',
        route: '/resident/complaint',
      ),
      const _DrawerDestination(
        icon: Icons.forum_outlined,
        label: 'Complaints',
        route: '/resident/complaints',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadProfile(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DrawerHeader(
                  profile: profile,
                  loading: snapshot.connectionState == ConnectionState.waiting,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final location =
                          GoRouter.of(
                            context,
                          ).routeInformationProvider.value.location;
                      final isActive = location.startsWith(item.route);
                      return _NavigationTile(item: item, active: isActive);
                    },
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemCount: navItems.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: const BorderRadius.all(AppRadii.lg),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Need help? Reach the society office.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            context.go('/');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool loading;
  const _DrawerHeader({required this.profile, required this.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile['name'] as String? ?? 'Resident';
    final flat = profile['flat'] as String? ?? '- -';
    final email = profile['email'] as String? ?? '';
    final avatarUrl = profile['avatar'] as String?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
            child:
                (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'R',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Flat $flat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerDestination {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _NavigationTile extends StatelessWidget {
  final _DrawerDestination item;
  final bool active;
  const _NavigationTile({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color:
          active
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
      borderRadius: const BorderRadius.all(AppRadii.lg),
      child: InkWell(
        borderRadius: const BorderRadius.all(AppRadii.lg),
        onTap: () => context.go(item.route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                item.icon,
                color:
                    active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color:
                        active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (active)
                Icon(Icons.chevron_right, color: theme.colorScheme.primary)
              else
                Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
