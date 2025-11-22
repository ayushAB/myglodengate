import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_drawer.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: const GradientAppBar(title: 'Dashboard', showLogoutButton: true),
      drawer: const GradientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final crossAxisCount = isWide ? 3 : 2;
            final cards = <_DashCardData>[
              _DashCardData(
                title: 'Visitors',
                icon: Icons.people_alt_outlined,
                color: Colors.teal,
                onTap: () => context.push('/visitors'),
              ),
              _DashCardData(
                title: 'Complaints',
                icon: Icons.report_gmailerrorred_outlined,
                color: Colors.orange,
                onTap: () => context.push('/resident/complaint'),
              ),
              _DashCardData(
                title: 'Profile',
                icon: Icons.person_outline,
                color: Colors.indigo,
                onTap: () => context.push('/resident/profile'),
              ),
            ];

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: isWide ? 1.4 : 1.0,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final item = cards[index];
                return InkWell(
                  borderRadius: const BorderRadius.all(AppRadii.lg),
                  onTap: item.onTap,
                  child: AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: item.color.withOpacity(0.12),
                          child: Icon(item.icon, color: item.color, size: 28),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashCardData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _DashCardData({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
