import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../onboarding/onboarding_cache.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Fire-and-forget: start buffering the third slide's video in the background
    OnboardingCache.instance.preload();

    // Splash screen logo display delay (2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Decorative background blobs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium animated logo badge
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                      )
                      .then()
                      .shake(duration: 500.ms, hz: 2),
                  const SizedBox(height: 24),
                  Text(
                    'CloudNotes',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 36,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
                  const SizedBox(height: 8),
                  Text(
                    'The Premium College Notes Hub',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
                ],
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}
