import 'package:flutter/material.dart';
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
      body: const Center(child: Text('Welcome, Resident/Admin!')),
    );
  }
}
