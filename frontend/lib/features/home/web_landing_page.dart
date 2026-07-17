import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class WebLandingPage extends StatelessWidget {
  const WebLandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Nav bar
            _buildNavBar(context, isDark, width),

            // Hero Section
            _buildHeroSection(context, isDark, width),

            // Statistics Section
            _buildStatsSection(context, isDark),

            // Trending Notes Grid
            _buildTrendingSection(context, width),

            // Popular Colleges
            _buildCollegesSection(context, isDark),

            // Testimonials
            _buildTestimonialsSection(context, width),

            // FAQ Section
            _buildFAQSection(context, width),

            // Footer
            _buildFooter(context, isDark, width),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, bool isDark, double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width > 1200 ? 120 : 40, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'EduMarket',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (width > 700)
            Row(
              children: [
                _navLink('Home', active: true),
                const SizedBox(width: 32),
                _navLink('Browse Notes'),
                const SizedBox(width: 32),
                _navLink('Community'),
                const SizedBox(width: 32),
                _navLink('AI Tool Suite'),
              ],
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              GradientButton(
                height: 44,
                text: 'Join Now',
                onPressed: () => context.go('/auth/register'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label, {bool active = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: active ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark, double width) {
    final padding = width > 1200 ? 120.0 : 40.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 80),
      child: Row(
        children: [
          // Left side branding
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ #1 College notes platform',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'The Premium Marketplace\nFor Academic Notes',
                  style: GoogleFonts.poppins(
                    fontSize: width > 1000 ? 54 : 38,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Buy verified PDF guides, PPT slide-decks, exam prep sheets, and tutorials. Upload your own, set your price, and earn on every transaction.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 36),
                
                // Embedded elegant search
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(Icons.search, color: AppColors.primary),
                      ),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by University, College, Subject...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GradientButton(
                        height: 48,
                        text: 'Search',
                        onPressed: () => context.push('/search'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
              ],
            ),
          ),
          
          if (width > 900) ...[
            const SizedBox(width: 60),
            // Right side graphic
            Expanded(
              child: GlassCard(
                borderRadius: 30,
                opacity: 0.05,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=120'),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aarti K.', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('IIT Delhi • Computer Science', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Top Seller', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Product card preview
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.analytics_rounded, size: 64, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Machine Learning Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹249', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text('4.9 (124 reviews)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 700.ms).slideX(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.surfaceDark.withOpacity(0.4) : AppColors.borderLight.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('50K+', 'Premium Notes Uploaded'),
          _statItem('120K+', 'Happy Students Enrolled'),
          _statItem('400+', 'Colleges Covered'),
          _statItem('₹15L+', 'Earned by Top Sellers'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(BuildContext context, double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width > 1200 ? 120 : 40, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Trending Notes Today',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              OutlinedButton(
                onPressed: () => context.push('/search'),
                child: const Text('Browse All Notes'),
              ),
            ],
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width > 1000 ? 4 : (width > 600 ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final titles = [
                'Data Structures Complete',
                'Intro to Microeconomics',
                'Advanced Thermodynamics',
                'Organic Chemistry Basics'
              ];
              final prices = ['₹199', 'Free', '₹299', '₹149'];
              return GestureDetector(
                onTap: () => context.push('/notes/$index'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: [
                              AppColors.primaryGradient,
                              AppColors.accentGradient,
                              LinearGradient(colors: [Colors.green, Colors.cyan]),
                              LinearGradient(colors: [Colors.orange, Colors.red])
                            ][index],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(
                            child: Icon(Icons.library_books, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titles[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('IIT Delhi • CSE', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  prices[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: prices[index] == 'Free' ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 2),
                                    Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollegesSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.surfaceDark.withOpacity(0.2) : AppColors.borderLight.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Text(
            'FEATURED COLLEGES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _collegeLogo('IIT Bombay'),
                const SizedBox(width: 48),
                _collegeLogo('BITS Pilani'),
                const SizedBox(width: 48),
                _collegeLogo('Delhi University'),
                const SizedBox(width: 48),
                _collegeLogo('VIT University'),
                const SizedBox(width: 48),
                _collegeLogo('SRM Institute'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collegeLogo(String name) {
    return Opacity(
      opacity: 0.6,
      child: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context, double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width > 1200 ? 120 : 40, vertical: 80),
      child: Column(
        children: [
          Text(
            'Loved By Students & Teachers',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _testimonialCard('Rohan M., Student', 'The notes quality here is insane! I cracked my Algorithms final easily. Highly recommended!'),
              _testimonialCard('Prof. Suresh D., Teacher', 'I upload my lectures notes and class PPTs. Earned ₹40k last month alone side my teaching salary.'),
              _testimonialCard('Kritika S., Student', 'The AI Summary feature is a life saver. I summarize 100-page booklets in 3 seconds before the exam.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testimonialCard(String author, String quote) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, size: 36, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            quote,
            style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Text(
            author,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width > 1200 ? 120 : 40, vertical: 80),
      child: Column(
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Column(
              children: [
                ExpansionTile(
                  title: Text('Are the notes verified for quality?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Yes. All notes uploaded undergo review checking by our team and student community before they are featured.'),
                    )
                  ],
                ),
                ExpansionTile(
                  title: Text('How do I make withdrawals?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('You can link your UPI or Bank Account in your Seller Dashboard and request a withdrawal when your earnings cross ₹500.'),
                    )
                  ],
                ),
                ExpansionTile(
                  title: Text('How does the AI suite work?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('We parse the uploaded PDF and run summarizations, translation and generate quizzes. You spend "EduCoins" to use these services.'),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width > 1200 ? 120 : 40, vertical: 60),
      color: isDark ? AppColors.surfaceDark : AppColors.borderLight.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EduMarket', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('The Premium Marketplace for study guides.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const Row(
                children: [
                  Text('Privacy Policy', style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 24),
                  Text('Terms of Use', style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 24),
                  Text('Contact Us', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          const Text('© 2026 EduMarket Inc. All rights reserved.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
