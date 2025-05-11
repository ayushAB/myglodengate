import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Features/Resitdent/Widget/resident_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentProfileScreen extends StatelessWidget {
  const ResidentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    return GradientScaffold(
      appBar: GradientAppBar(title: "My Profile"),
      drawer: const ResidentDrawer(),
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Placeholder
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email: ${user.email}",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                // User ID
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "User ID: ${user.id}",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const Spacer(),

                // Update Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () {
                      // Future: Navigate to update profile screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Update Profile coming soon!"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Update Profile"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
