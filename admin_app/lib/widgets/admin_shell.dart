import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../core/api_service.dart';

// ─── Breakpoint ────────────────────────────────────────────────────────────
const double kSidebarBreakpoint = 700;

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent the hardware back button from popping/closing the shell
      canPop: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < kSidebarBreakpoint;
          return isMobile
              ? _MobileShell(child: child)
              : _DesktopShell(child: child);
        },
      ),
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
    final location = GoRouterState.of(context).matchedLocation;
    
    // Bottom nav items
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Overview', 'path': '/'},
      {'icon': Icons.fact_check_rounded, 'label': 'Audit', 'path': '/notes'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Orders', 'path': '/orders'},
      {'icon': Icons.view_carousel_rounded, 'label': 'Banners', 'path': '/banners'},
    ];

    return Scaffold(
      backgroundColor: kBg,
      drawer: Drawer(
        backgroundColor: kSurface,
        child: SafeArea(child: _SidebarContent()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(showMenuIcon: true),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final path = item['path'] as String;
                final isActive = location == path || (path != '/' && location.startsWith(path));
                final color = isActive ? kPrimary : kTextMuted;
                return GestureDetector(
                  onTap: () => context.go(path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? kPrimary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
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
    _NavItem('Reports',        Icons.gavel_rounded,          '/reports'),
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
class _TopBar extends StatefulWidget {
  final bool showMenuIcon;
  const _TopBar({required this.showMenuIcon});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await AdminApiService.request('GET', '/api/notifications');
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _unreadCount = res.data['unreadCount'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _NotificationsSheet(
          onRead: () {
            _fetchUnreadCount();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final titles = {
      '/': 'Overview',
      '/notes': 'Notes Audit',
      '/users': 'User Directory',
      '/disputes': 'Disputes',
      '/reports': 'Reports',
      '/settings': 'Settings',
    };
    final title = titles[location] ?? 'Admin Console';

    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Row(
          children: [
            if (widget.showMenuIcon)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: kTextMuted),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            if (widget.showMenuIcon) const SizedBox(width: 4),
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
                  onPressed: () => _showNotificationsModal(context),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration:
                          const BoxDecoration(shape: BoxShape.circle, color: kError),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final VoidCallback onRead;
  const _NotificationsSheet({required this.onRead});

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await AdminApiService.request('GET', '/api/notifications');
      if (res != null && res.data['success'] == true) {
        setState(() {
          _notifications = res.data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await AdminApiService.request('PUT', '/api/notifications/$id/read');
      widget.onRead();
      _fetch();
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_notifications.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(child: Text('No notifications right now.', style: GoogleFonts.inter(color: kTextMuted))),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary)),
              IconButton(icon: const Icon(Icons.close, color: kTextMuted), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
        const Divider(height: 1, color: kBorder),
        Expanded(
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notif = _notifications[index];
              final isRead = notif['isRead'] ?? false;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimary.withValues(alpha: 0.1),
                  child: Icon(Icons.notifications_active_rounded, color: isRead ? kTextMuted : kPrimary, size: 18),
                ),
                title: Text(notif['title'] ?? 'Notification', style: GoogleFonts.inter(color: kTextPrimary, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                subtitle: Text(notif['message'] ?? '', style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                trailing: isRead ? null : IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: kSuccess, size: 20),
                  onPressed: () => _markAsRead(notif['_id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
