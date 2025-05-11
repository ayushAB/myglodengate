import 'package:go_router/go_router.dart';
import 'package:myglodengate/Features/Auth/Screen/login_screen.dart';
import 'package:myglodengate/Features/Auth/Screen/signup_screen.dart';
import 'package:myglodengate/Features/Dashboard/screen/dashboard_screen.dart';
import 'package:myglodengate/Features/Guard/Screen/guard_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/complaint_form_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/complaint_list_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/resident_dashboard_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/resident_profile_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/visitor_list_screen.dart';
import 'package:myglodengate/Features/SplashScreen/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/resident/profile',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) => const DashboardScreen(),
      ),
      GoRoute(path: '/security', builder: (context, _) => const GuardScreen()),
      GoRoute(path: '/visitors', builder: (_, __) => const VisitorListScreen()),
      GoRoute(path: '/signup', builder: (context, _) => const SignupScreen()),
      GoRoute(
        path: '/resident/dashboard',
        builder: (_, __) => const ResidentDashboardScreen(),
      ),
      GoRoute(
        path: '/resident/visitors',
        builder: (_, __) => const VisitorListScreen(),
      ),
      GoRoute(
        path: '/resident/complaint',
        builder: (_, __) => const ComplaintFormScreen(),
      ),
      GoRoute(
        path: '/resident/complaint',
        builder: (_, __) => const ComplaintListScreen(),
      ),
      GoRoute(
        path: '/resident/profile',
        builder: (_, __) => const ResidentProfileScreen(),
      ),
    ],
  );
}
