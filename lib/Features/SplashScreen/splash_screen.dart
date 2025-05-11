import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;

      if (session != null) {
        final userId = session.user.id;

        final response =
            await Supabase.instance.client
                .from('users')
                .select('role')
                .eq('id', userId)
                .single();

        final role = response['role'];
        print(role);

        switch (role) {
          case 'admin':
            context.go('/dashboard');
            break;
          case 'security':
            context.go('/security');
            break;
          default:
            context.go('/login');
            break;
        }
      } else {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const GradientScaffold(
      body: Center(
        child: CircularProgressIndicator(), // Or your splash logo
      ),
    );
  }
}
