import 'package:flutter/material.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';

class GuardScreen extends StatelessWidget {
  const GuardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: GradientAppBar(title: 'Guard Panel'),
      body: const Center(child: Text('Welcome, Security!')),
    );
  }
}
