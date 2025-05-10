import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/gradients.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool
  showLogoutButton; // New flag to control the visibility of the logout button

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.showLogoutButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: [
        if (showLogoutButton)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final supabase = Supabase.instance.client;
              await supabase.auth.signOut(); // Log out user
              context.go('/login'); // Navigate to login screen using GoRouter
            },
          ),
        if (actions != null) ...actions!, // Allow other actions to be passed
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
      ),
      backgroundColor: Colors.transparent,
      elevation: 6,
    );
  }
}
