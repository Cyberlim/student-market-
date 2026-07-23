import 'package:go_router/go_router.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/dashboard/overview_screen.dart';
import '../../features/notes/notes_audit_screen.dart';
import '../../features/users/user_directory_screen.dart';
import '../../features/disputes/disputes_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/banners/banners_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../widgets/admin_shell.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const OverviewScreen(),
        ),
        GoRoute(
          path: '/notes',
          builder: (_, __) => const NotesAuditScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (_, __) => const UserDirectoryScreen(),
        ),
        GoRoute(
          path: '/disputes',
          builder: (_, __) => const DisputesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/banners',
          builder: (_, __) => const BannersScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (_, __) => const ReportsScreen(),
        ),
      ],
    ),
  ],
);
