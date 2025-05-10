import 'package:flutter/material.dart';
import 'package:myglodengate/App/app_router.dart';
import 'package:myglodengate/Core/Theme/Theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://itbsyxuyzbcianucivvi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0YnN5eHV5emJjaWFudWNpdnZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY3ODYwOTgsImV4cCI6MjA2MjM2MjA5OH0.RJCsndlf7SD21oxYTob6h8UnUt1TGcckT6Y3jLo7CEI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Golden Gate',
      theme: AppTheme.lightTheme, // 👈 Apply theme
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
