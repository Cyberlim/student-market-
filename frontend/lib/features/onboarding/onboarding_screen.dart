import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'onboarding_cache.dart';

// ─── OnboardingScreen Stateful Widget ─────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Find Premium Notes',
      description: 'Access top-tier hand-written and digital notes, verified exam resources, and PPTs from top colleges.',
      icon: Icons.search_rounded,
      gradient: AppColors.primaryGradient,
      videoUrl: 'https://res.cloudinary.com/dbtxwousd/video/upload/v1782985156/onpdsw3iwffo8pbqmxq9.gif',
    ),
    OnboardingItem(
      title: 'Share & Earn Revenue',
      description: 'Upload your notes, set your own prices, track sales, and withdraw real money directly to your account.',
      icon: Icons.monetization_on_rounded,
      gradient: AppColors.accentGradient,
      videoUrl: 'https://res.cloudinary.com/dbtxwousd/image/upload/v1782979755/szbmysjmyukr9dqssegt.gif',
    ),
    OnboardingItem(
      title: 'AI Study Assistant',
      description: 'Instantly summarize PDFs, generate flashcards, create custom practice quizzes, and explain tough sections.',
      icon: Icons.psychology_rounded,
      gradient: LinearGradient(
        colors: [AppColors.accent, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      videoUrl: 'https://res.cloudinary.com/dbtxwousd/video/upload/v1782991108/yrrgp7zpvfxhrx0yfqfx.gif',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-play the current slide controller if it is already initialized in cache
    OnboardingCache.instance.preload().then((_) {
      if (mounted) {
        setState(() {
          final currController = OnboardingCache.instance.controllers[_currentPage];
          if (currController != null && currController.value.isInitialized) {
            currController.play();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    OnboardingCache.instance.dispose(); // clean up preloaded video controllers from memory on exit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background circle blobs
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: _currentPage == 0 ? -100 : (_currentPage == 1 ? -150 : 50),
            right: _currentPage == 0 ? -100 : (_currentPage == 1 ? 100 : -150),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _items[_currentPage].gradient.colors.first.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            bottom: _currentPage == 0 ? -100 : (_currentPage == 1 ? 200 : -120),
            left: _currentPage == 0 ? -100 : (_currentPage == 1 ? -150 : 100),
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _items[_currentPage].gradient.colors.last.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        // Pause previous cached controller
                        final prevController = OnboardingCache.instance.controllers[_currentPage];
                        if (prevController != null && prevController.value.isInitialized) {
                          prevController.pause();
                        }
                        
                        _currentPage = index;
                        
                        // Play current cached controller
                        final currController = OnboardingCache.instance.controllers[_currentPage];
                        if (currController != null && currController.value.isInitialized) {
                          currController.play();
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Square card layout with custom drop shadow effect
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.gradient.colors.first.withOpacity(isDark ? 0.25 : 0.15),
                                      blurRadius: 28,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: GlassCard(
                                  borderRadius: 30,
                                  blur: 20,
                                  opacity: 0.08,
                                  padding: const EdgeInsets.all(12),
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: item.gradient.colors.first.withOpacity(isDark ? 0.4 : 0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.gradient.colors.first.withOpacity(isDark ? 0.25 : 0.15),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: item.videoUrl.endsWith('.gif')
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.network(
                                              item.videoUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(
                                                    color: AppColors.primary,
                                                    strokeWidth: 3,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    gradient: item.gradient,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    item.icon,
                                                    size: 50,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : _buildVideoPlayer(index, item),
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .scale(duration: 700.ms, curve: Curves.easeOutBack)
                                .fadeIn(duration: 500.ms),
                            const SizedBox(height: 40),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                            ).animate(key: ValueKey('title_$index')).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0.0),
                            const SizedBox(height: 16),
                            Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                            ).animate(key: ValueKey('desc_$index')).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0.0),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Page Indicators and Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: _currentPage == index ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              gradient: _currentPage == index ? _items[index].gradient : null,
                              color: _currentPage == index
                                  ? null
                                  : (isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      GradientButton(
                        width: double.infinity,
                        gradient: _items[_currentPage].gradient,
                        text: _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                        onPressed: () {
                          if (_currentPage == _items.length - 1) {
                            context.go('/auth/login');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Preloaded and cached video player layout
  Widget _buildVideoPlayer(int index, OnboardingItem item) {
    final controller = OnboardingCache.instance.controllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final String videoUrl;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.videoUrl,
  });
}
