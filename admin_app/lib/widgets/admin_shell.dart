import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

// ─── Breakpoint ────────────────────────────────────────────────────────────
const double kSidebarBreakpoint = 700;

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kSidebarBreakpoint;
        return isMobile
            ? _MobileShell(child: child)
            : _DesktopShell(child: child);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// DESKTOP SHELL  (fixed sidebar)
// ─────────────────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          _SidebarContent(),
          Expanded(
            child: Column(
              children: [
                _TopBar(showMenuIcon: false),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MOBILE SHELL  (drawer-based)
// ─────────────────────────────────────────────────────────
class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _TopBar(showMenuIcon: true),
      ),
      drawer: Drawer(
        backgroundColor: kSurface,
        child: SafeArea(child: _SidebarContent()),
      ),
      body: child,
    );
  }
}

// ─────────────────────────────────────────────────────────
// SHARED SIDEBAR CONTENT
// ─────────────────────────────────────────────────────────
class _SidebarContent extends StatelessWidget {
  static const _items = [
    _NavItem('Overview',       Icons.dashboard_rounded,      '/'),
    _NavItem('Notes Audit',    Icons.fact_check_rounded,     '/notes'),
    _NavItem('Orders Manager', Icons.local_shipping_rounded, '/orders'),
    _NavItem('User Directory', Icons.people_rounded,         '/users'),
    _NavItem('Disputes',       Icons.report_problem_rounded, '/disputes'),
    _NavItem('Banners Manager', Icons.view_carousel_rounded, '/banners'),
    _NavItem('Settings',       Icons.settings_rounded,       '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: 240,
      color: kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EduMarket',
                        style: GoogleFonts.inter(
                            color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Admin Console',
                        style: GoogleFonts.inter(
                            color: kTextMuted, fontSize: 10, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 12),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _items.map((item) {
                final isActive = location == item.path ||
                    (item.path != '/' && location.startsWith(item.path));
                return _SidebarTile(item: item, isActive: isActive);
              }).toList(),
            ),
          ),

          const Divider(color: kBorder, height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: kPrimary,
                      child: Text('AD',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin User',
                              style: GoogleFonts.inter(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          Text('Super Administrator',
                              style: GoogleFonts.inter(color: kTextMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // close drawer if open
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 14, color: kTextMuted),
                  label: Text('Sign Out',
                      style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                    side: const BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _SidebarTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          // Close drawer on mobile before navigating
          if (Scaffold.of(context).hasDrawer) {
            Navigator.of(context).pop();
          }
          context.go(item.path);
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? kPrimary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: isActive ? kPrimary : kTextMuted),
              const SizedBox(width: 12),
              Text(item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? kPrimary : kTextMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label, path;
  final IconData icon;
  const _NavItem(this.label, this.icon, this.path);
}

// ─────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool showMenuIcon;
  const _TopBar({required this.showMenuIcon});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final titles = {
      '/': 'Overview',
      '/notes': 'Notes Audit',
      '/users': 'User Directory',
      '/disputes': 'Disputes',
      '/settings': 'Settings',
    };
    final title = titles[location] ?? 'Admin Console';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          if (showMenuIcon)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: kTextMuted),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (showMenuIcon) const SizedBox(width: 4),
          Text(title,
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          // Live status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: kSuccess)),
                const SizedBox(width: 6),
                Text('Live',
                    style: GoogleFonts.inter(
                        color: kSuccess, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: kTextMuted),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7, height: 7,
                  decoration:
                      const BoxDecoration(shape: BoxShape.circle, color: kError),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
