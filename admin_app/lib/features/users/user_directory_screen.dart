import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

class UserDirectoryScreen extends StatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  State<UserDirectoryScreen> createState() => _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends State<UserDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/admin/users');
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _users = data.map<Map<String, dynamic>>((u) {
            return {
              'id': u['_id'] ?? u['id'] ?? '',
              'name': u['name'] ?? 'Unknown',
              'email': u['email'] ?? '',
              'role': u['role'] ?? 'Student',
              'college': u['college'] ?? 'N/A',
              'uploads': u['notesCount'] ?? 0,
              'coins': u['coins'] ?? 0,
              'banned': u['isBanned'] ?? false,
              'joined': u['createdAt'] != null
                  ? (u['createdAt'] as String).substring(0, 10)
                  : 'N/A',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) =>
        u['name'].toString().toLowerCase().contains(q) ||
        u['email'].toString().toLowerCase().contains(q) ||
        u['college'].toString().toLowerCase().contains(q)).toList();
  }

  Future<void> _toggleBan(Map<String, dynamic> u) async {
    final userId = u['id'] as String;
    try {
      final response = await AdminApiService.request('PUT', '/api/admin/users/$userId/ban');
      if (response != null && response.statusCode == 200) {
        await _loadUsers();
        final banned = !(u['banned'] as bool);
        _snack('${u['name']} ${banned ? 'suspended' : 'reactivated'}.', banned ? kError : kSuccess);
      } else {
        _snack('Failed to update user status.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  void _showCoinDialog(Map<String, dynamic> u) {
    final ctrl = TextEditingController(text: '${u['coins']}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kBorder)),
        title: Text('Adjust Coins — ${u['name']}',
            style: GoogleFonts.inter(
                color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
              labelText: 'New coin balance',
              labelStyle: TextStyle(color: kTextMuted)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: kTextMuted))),
          ElevatedButton(
            onPressed: () async {
              final newCoins = int.tryParse(ctrl.text) ?? u['coins'];
              Navigator.pop(context);
              final userId = u['id'] as String;
              try {
                final response = await AdminApiService.request(
                  'PUT', '/api/admin/users/$userId/coins',
                  data: {'coins': newCoins},
                );
                if (response != null && response.statusCode == 200) {
                  await _loadUsers();
                  _snack('Coin balance updated.', kSuccess);
                } else {
                  _snack('Failed to update coins.', kError);
                }
              } catch (e) {
                _snack('Error: $e', kError);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final users = _filtered;
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      if (_loading) {
        return const Center(child: CircularProgressIndicator(color: kPrimary));
      }
      return RefreshIndicator(
        onRefresh: _loadUsers,
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header + search
            if (isMobile) ...[
              Text('User Directory',
                  style: GoogleFonts.inter(
                      color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${_users.length} registered accounts',
                  style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: kTextPrimary, fontSize: 13),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                  hintText: 'Search name, email, college…',
                  isDense: true,
                ),
              ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('User Directory',
                        style: GoogleFonts.inter(
                            color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('${_users.length} registered accounts',
                        style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                  ]),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: kTextPrimary, fontSize: 13),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                        hintText: 'Search name, email, college…',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Content
            users.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No users match your search.',
                        style: GoogleFonts.inter(color: kTextMuted, fontSize: 13))))
                : isMobile
                    ? Column(
                        children: List.generate(
                            users.length, (i) => _UserCard(u: users[i], index: i,
                                onBan: () => _toggleBan(users[i]),
                                onCoins: () => _showCoinDialog(users[i]))))
                    : _buildDesktopTable(users),
          ],
        ),
        ),
      );
    });
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> users) {
    return Container(
      decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: kBorder))),
            child: Row(children: [
              _th('User', 3), _th('Role'), _th('College', 2),
              _th('Uploads'), _th('Coins'), _th('Joined'), _th('Status'), _th('Actions', 2),
            ]),
          ),
          // Rows
          ...List.generate(users.length, (i) {
            final u = users[i];
            final isBanned  = u['banned'] as bool;
            final isTeacher = u['role'] == 'Teacher';
            final roleColor = isTeacher ? kSuccess : kPrimary;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                border: i < users.length - 1
                    ? const Border(bottom: BorderSide(color: kBorder))
                    : null,
              ),
              child: Row(children: [
                // User
                Expanded(flex: 3, child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(u['name'][0],
                        style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['name'],
                        style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(u['email'],
                        style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ])),
                ])),
                Expanded(child: _RoleBadge(u['role'], roleColor)),
                Expanded(flex: 2, child: Text(u['college'], style: GoogleFonts.inter(color: kTextMuted, fontSize: 12))),
                Expanded(child: Text('${u['uploads']}', style: GoogleFonts.inter(color: kTextMuted, fontSize: 12))),
                Expanded(child: Text('${u['coins']}', style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text(u['joined'], style: GoogleFonts.inter(color: kTextMuted, fontSize: 12))),
                Expanded(child: _StatusBadge(isBanned)),
                Expanded(flex: 2, child: Row(children: [
                  _SmallBtn('Coins',                 kPrimary, () => _showCoinDialog(u)),
                  const SizedBox(width: 6),
                  _SmallBtn(isBanned ? 'Unban' : 'Suspend', isBanned ? kSuccess : kError, () => _toggleBan(u), filled: true),
                ])),
              ]),
            ).animate().fadeIn(duration: 220.ms, delay: (i * 25).ms);
          }),
        ],
      ),
    );
  }

  Widget _th(String l, [int flex = 1]) => Expanded(
        flex: flex,
        child: Text(l,
            style: GoogleFonts.inter(
                color: kTextMuted, fontWeight: FontWeight.w600, fontSize: 11)));
}

// ── Mobile user card ─────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> u;
  final int index;
  final VoidCallback onBan, onCoins;
  const _UserCard({required this.u, required this.index, required this.onBan, required this.onCoins});

  @override
  Widget build(BuildContext context) {
    final isBanned  = u['banned'] as bool;
    final isTeacher = u['role'] == 'Teacher';
    final roleColor = isTeacher ? kSuccess : kPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBanned ? kError.withValues(alpha: 0.3) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top: avatar + name + role badge
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(u['name'][0],
                style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['name'],
                style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(u['email'],
                style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ])),
          _RoleBadge(u['role'], roleColor),
        ]),
        const SizedBox(height: 12),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 10),
        // Stats row
        Row(children: [
          _stat(Icons.school_outlined,    u['college'],     flex: true),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _stat(Icons.upload_file_outlined, '${u['uploads']} uploads'),
          const SizedBox(width: 20),
          _stat(Icons.monetization_on_outlined, '${u['coins']} coins'),
          const SizedBox(width: 20),
          _stat(Icons.calendar_today_outlined, u['joined']),
        ]),
        const SizedBox(height: 12),
        // Status + actions
        Row(children: [
          _StatusBadge(isBanned),
          const Spacer(),
          TextButton.icon(
            onPressed: onCoins,
            icon: const Icon(Icons.monetization_on_outlined, size: 14, color: kPrimary),
            label: Text('Coins', style: GoogleFonts.inter(color: kPrimary, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onBan,
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? kSuccess : kError,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isBanned ? 'Unban' : 'Suspend',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          ),
        ]),
      ]),
    ).animate().fadeIn(duration: 260.ms, delay: (index * 40).ms);
  }

  Widget _stat(IconData icon, String text, {bool flex = false}) {
    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: kTextMuted),
      const SizedBox(width: 4),
      flex
          ? Flexible(child: Text(text, style: GoogleFonts.inter(color: kTextMuted, fontSize: 11), overflow: TextOverflow.ellipsis))
          : Text(text, style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
    ]);
    return flex ? Expanded(child: child) : child;
  }
}

// ── Shared badge widgets ──────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge(this.role, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(role,
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool banned;
  const _StatusBadge(this.banned);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: (banned ? kError : kSuccess).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(banned ? 'Suspended' : 'Active',
            style: GoogleFonts.inter(
                color: banned ? kError : kSuccess,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      );
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _SmallBtn(this.label, this.color, this.onTap, {this.filled = false});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ),
      );
}
