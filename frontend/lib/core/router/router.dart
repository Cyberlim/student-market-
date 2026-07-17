import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/complete_profile_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/web_landing_page.dart';
import '../../features/search/search_screen.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../features/notes/note_upload_screen.dart';
import '../../features/seller/seller_dashboard.dart';
import '../../features/buyer/buyer_dashboard.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/community/community_forum.dart';
import '../../features/ai_features/ai_panel.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/order_history_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../widgets/main_shell.dart';

class ResponsiveHomeWrapper extends StatelessWidget {
  const ResponsiveHomeWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return const WebLandingPage();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return OtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    
    // Bottom navigation/Sidebar shell
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ResponsiveHomeWrapper(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/forum',
          builder: (context, state) => const CommunityForum(),
        ),
        GoRoute(
          path: '/ai',
          builder: (context, state) => const AIPanel(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Fully-covering sub-routes
    GoRoute(
      path: '/notes/upload',
      builder: (context, state) => const NoteUploadScreen(),
    ),
    GoRoute(
      path: '/notes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return NoteDetailScreen(noteId: id);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/profile/addresses',
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: '/seller',
      builder: (context, state) => const SellerDashboard(),
    ),
    GoRoute(
      path: '/buyer',
      builder: (context, state) => const BuyerDashboard(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboard(),
    ),
  ],
);
