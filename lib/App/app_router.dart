import 'package:go_router/go_router.dart';
import 'package:myglodengate/Features/Auth/Screen/login_screen.dart';
import 'package:myglodengate/Features/Complaint/Screen/complaint_form_screen.dart';
import 'package:myglodengate/Features/Dashboard/screen/dashboard_screen.dart';
import 'package:myglodengate/Features/Guard/Screen/guard_screen.dart';
import 'package:myglodengate/Features/Visitor/Screen/visitor_list_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) => const DashboardScreen(),
      ),
      GoRoute(path: '/guard', builder: (context, _) => const GuardScreen()),
      GoRoute(path: '/visitors', builder: (_, __) => const VisitorListScreen()),
      GoRoute(
        path: '/complaint',
        builder: (_, __) => const ComplaintFormScreen(),
      ),
    ],
  );
}
