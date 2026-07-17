import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';
import 'glass_card.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/ai')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Default to Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/ai');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _getSelectedIndex(context);

    // Desktop Layout (No bottom bar, page manages its own navigation or we use side navigation)
    if (isDesktop) {
      return Scaffold(
        body: widget.child,
      );
    }

    // Mobile Layout (Floating glass bottom navigation)
    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/upload'),
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: const _CustomFabLocation(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: GlassCard(
          borderRadius: 24,
          blur: 16,
          opacity: isDark ? 0.08 : 0.06,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Home', selectedIndex),
              _buildNavItem(1, Icons.search, Icons.search, 'Search', selectedIndex),
              _buildNavItem(2, Icons.psychology, Icons.psychology_outlined, 'AI Tool', selectedIndex),
              _buildNavItem(3, Icons.person, Icons.person_outline, 'Profile', selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1) 
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected 
                  ? AppColors.primary 
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFabLocation extends FloatingActionButtonLocation {
  const _CustomFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width - 72.0;
    // Positioned with a slightly larger gap above the glass bottom bar
    final double fabY = scaffoldGeometry.scaffoldSize.height - 168.0;
    return Offset(fabX, fabY);
  }
}
