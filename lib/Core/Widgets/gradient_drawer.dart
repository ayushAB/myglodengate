import 'package:flutter/material.dart';
import '../theme/gradients.dart'; // Assuming your gradients are defined here
import 'package:go_router/go_router.dart';

class GradientDrawer extends StatelessWidget {
  const GradientDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient:
              AppGradients.primaryGradient, // Apply the gradient background
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color:
                    Colors
                        .transparent, // Transparent so the gradient is visible
              ),
              child: Text(
                'App Drawer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.go('/dashboard'); // Navigate to Dashboard
              },
            ),
            ListTile(
              title: const Text('Guard', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.go('/guard'); // Navigate to Guard screen
              },
            ),
            ListTile(
              title: const Text(
                'Visitors',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                context.go('/visitors'); // Navigate to Visitors screen
              },
            ),
            ListTile(
              title: const Text(
                'Complaints',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                context.go('/complaint'); // Navigate to Complaints screen
              },
            ),
            ListTile(
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Add your logout logic here
                context.go('/login'); // Navigate to login screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
