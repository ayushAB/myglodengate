import 'package:flutter/material.dart';

class GuardScreen extends StatelessWidget {
  const GuardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guard Panel')),
      body: const Center(child: Text('Welcome, Security!')),
    );
  }
}
