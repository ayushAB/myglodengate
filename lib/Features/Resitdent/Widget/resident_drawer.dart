import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Theme/Gradients.dart';

class ResidentDrawer extends StatelessWidget {
  const ResidentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: const BoxDecoration(
              gradient:
                  AppGradients.primaryGradient, // Apply the gradient background
            ),
            child: Text('Resident Menu'),
          ),
          ListTile(
            title: const Text('Dashboard'),
            onTap: () => context.go('/resident/dashboard'),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () => context.go('/resident/profile'),
          ),
          ListTile(
            title: const Text('Visitors'),
            onTap: () => context.go('/resident/visitors'),
          ),
          ListTile(
            title: const Text('File Complaint'),
            onTap: () => context.go('/resident/complaint'),
          ),

          ListTile(
            title: const Text('Complaints'),
            onTap: () => context.go('/resident/complaints'),
          ),
        ],
      ),
    );
  }
}
