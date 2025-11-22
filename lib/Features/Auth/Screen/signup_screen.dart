import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myglodengate/Core/Constants/app_roles.dart';
import 'package:myglodengate/Core/Theme/Gradients.dart';
import 'package:myglodengate/Core/Theme/design_system.dart';
import 'package:myglodengate/Core/Widgets/app_card.dart';
import 'package:myglodengate/Core/Widgets/gradient_app_bar.dart';
import 'package:myglodengate/Core/Widgets/gradient_scaffold.dart';
import 'package:myglodengate/Core/Widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = AppRoles.resident;
  bool _loading = false;

  final _roles = [AppRoles.admin, AppRoles.resident, AppRoles.security];

  Future<void> _handleSignup() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      final userId = user?.id;

      if (userId == null) {
        throw Exception("User ID is null after signup");
      }

      // Wait a moment to ensure auth.users table is updated
      await Future.delayed(const Duration(milliseconds: 500));

      await Supabase.instance.client.from('users').insert({
        'id': userId,
        'email': email,
        'role': _selectedRole,
      });

      if (!mounted) return;
      context.go('/dashboard');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("DB Error: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField(
                    value: _selectedRole,
                    items:
                        _roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() {
                          _selectedRole = value!;
                        }),
                    decoration: const InputDecoration(
                      labelText: 'Select Role',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Sign Up',
                    loading: _loading,
                    onPressed: _handleSignup,
                    icon: Icons.person_add_alt,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
