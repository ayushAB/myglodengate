import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Features/Auth/Service/auth_service.dart';

class RoleNavigator {
  static final _authService = AuthService();

  static Future<void> navigateUserBasedOnRole(BuildContext context) async {
    final role = await _authService.getUserRole();
    print(role);
    if (role == 'admin') {
      context.go('/dashboard');
    } else if (role == 'security') {
      context.go('/guard/dashboard');
    } else if (role == 'resident') {
      context.go('/resident/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unknown role. Access denied.")),
      );
    }
  }
}
