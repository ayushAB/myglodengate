import 'package:go_router/go_router.dart';
import 'package:myglodengate/Features/Auth/Screen/login_screen.dart';
import 'package:myglodengate/Features/Auth/Screen/signup_screen.dart';
import 'package:myglodengate/Features/Dashboard/screen/dashboard_screen.dart';
import 'package:myglodengate/Features/Guard/Screen/guard_dashboard_screen.dart';
import 'package:myglodengate/Features/Guard/Screen/guard_pending_visitors_screen.dart';
import 'package:myglodengate/Features/Guard/Screen/guard_visitors_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/complaint_form_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/complaint_list_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/resident_dashboard_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/resident_profile_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/visitor_list_screen.dart';
import 'package:myglodengate/Features/Resitdent/Screen/visitor_approval_screen.dart';
import 'package:myglodengate/Features/SplashScreen/splash_screen.dart';
import 'package:myglodengate/main.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, _) => const SignupScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/guard/dashboard',
        builder: (context, state) => const GuardDashboardScreen(),
      ),
      GoRoute(
        path: '/guard/pending-visitors',
        builder: (_, __) => const GuardPendingVisitorsScreen(),
      ),
      GoRoute(
        path: '/guard/visitors',
        builder: (context, state) => const GuardVisitorsScreen(),
      ),
      GoRoute(path: '/visitors', builder: (_, __) => const VisitorListScreen()),
      GoRoute(
        path: '/resident/dashboard',
        builder: (_, __) => const ResidentDashboardScreen(),
      ),
      GoRoute(
        path: '/resident/visitors',
        builder: (_, __) => const VisitorListScreen(),
      ),
      GoRoute(
        path: '/resident/visitor/:id',
        builder:
            (context, state) =>
                VisitorApprovalScreen(id: state.pathParameters['id']!),
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
