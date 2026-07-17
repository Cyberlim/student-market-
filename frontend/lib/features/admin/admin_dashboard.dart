import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Navigation active tab for Desktop/Web
  String _activeTab = 'overview';

  // Mock approval queue
  final List<Map<String, dynamic>> _pendingApprovals = [
    {'id': '101', 'title': 'Compiler Design Complete Notes.pdf', 'author': 'Prof. Swaminathan', 'college': 'BITS Pilani', 'price': '₹249', 'date': '2026-06-30'},
    {'id': '102', 'title': 'Fluid Mechanics formulas.docx', 'author': 'Rohan M.', 'college': 'IIT Bombay', 'price': 'Free', 'date': '2026-06-30'},
    {'id': '103', 'title': 'Computer Networks guide.pdf', 'author': 'Aarti K.', 'college': 'Delhi University', 'price': '₹149', 'date': '2026-06-29'},
  ];

  // Mock users database
  final List<Map<String, dynamic>> _usersList = [
    {'name': 'Alok Thakur', 'email': 'alok@iitb.ac.in', 'role': 'Student', 'college': 'IIT Bombay', 'notes': 3, 'coins': 150, 'isBanned': false},
    {'name': 'Prof. Swaminathan', 'email': 'swami@bits.ac.in', 'role': 'Teacher', 'college': 'BITS Pilani', 'notes': 12, 'coins': 4800, 'isBanned': false},
    {'name': 'Sanya Goel', 'email': 'sanya@du.ac.in', 'role': 'Student', 'college': 'Delhi University', 'notes': 0, 'coins': 50, 'isBanned': false},
    {'name': 'Rahul Sharma', 'email': 'rahul.sharma@gmail.com', 'role': 'Student', 'college': 'DTU', 'notes': 1, 'coins': 0, 'isBanned': true},
  ];

  // System Settings state
  double _commissionRate = 10.0;
  int _signupReward = 50;
  bool _manualVerificationOnly = true;

  // Search controller for user search tab
  final _searchQueryController = TextEditingController();

  void _approveDocument(int index) {
    setState(() {
      _pendingApprovals.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document approved! Published to marketplace.'), backgroundColor: AppColors.success),
    );
  }

  void _rejectDocument(int index) {
    setState(() {
      _pendingApprovals.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document rejected and uploader notified.'), backgroundColor: AppColors.error),
    );
  }

  void _toggleUserBan(int index) {
    setState(() {
      _usersList[index]['isBanned'] = !_usersList[index]['isBanned'];
    });
    final action = _usersList[index]['isBanned'] ? 'banned' : 'activated';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User account successfully $action.'), backgroundColor: AppColors.primary),
    );
  }

  void _adjustUserCoins(int index, int newCoins) {
    setState(() {
      _usersList[index]['coins'] = newCoins;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User coin balance adjusted successfully.'), backgroundColor: AppColors.success),
    );
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop) {
      return _buildWebLayout(isDark);
    } else {
      return _buildMobileLayout(isDark);
    }
  }

  // ==========================================
  // DESKTOP / WEB LAYOUT
  // ==========================================
  Widget _buildWebLayout(bool isDark) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(isDark),
          // Main content area
          Expanded(
            child: Container(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWebHeader(isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: _buildSelectedTabContent(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  'Admin Hub',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem('Overview', Icons.dashboard_rounded, 'overview'),
                _buildSidebarItem('Notes Audit', Icons.fact_check_rounded, 'notes', badge: _pendingApprovals.length),
                _buildSidebarItem('User Directory', Icons.people_rounded, 'users'),
                _buildSidebarItem('System Settings', Icons.settings_rounded, 'settings'),
              ],
            ),
          ),

          // Sidebar Footer Profile
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Super Administrator', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Main Site', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, String tabId, {int? badge}) {
    final isSelected = _activeTab == tabId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = tabId;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.08) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    color: isSelected 
                        ? AppColors.primary 
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                  ),
                ),
              ),
              if (badge != null && badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeader(bool isDark) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _activeTab[0].toUpperCase() + _activeTab.substring(1) + ' Console',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Row(
            children: [
              // System status check indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                    const SizedBox(width: 8),
                    const Text('API Server Healthy', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(bool isDark) {
    switch (_activeTab) {
      case 'overview':
        return _buildWebOverview(isDark);
      case 'notes':
        return _buildWebNotesAudit(isDark);
      case 'users':
        return _buildWebUserDirectory(isDark);
      case 'settings':
        return _buildWebSettings(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // WEB TAB: OVERVIEW
  // ==========================================
  Widget _buildWebOverview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI statistics Cards row
        Row(
          children: [
            Expanded(child: _buildWebKpiCard('Total Platform Revenue', '₹24,590', Icons.account_balance_wallet_rounded, AppColors.primary)),
            const SizedBox(width: 20),
            Expanded(child: _buildWebKpiCard('Total Registrations', '12,482', Icons.groups_rounded, AppColors.secondary)),
            const SizedBox(width: 20),
            Expanded(child: _buildWebKpiCard('Awaiting Document Audit', '${_pendingApprovals.length}', Icons.fact_check_rounded, Colors.amber)),
            const SizedBox(width: 20),
            Expanded(child: _buildWebKpiCard('Reported Issues', '4', Icons.report_problem_rounded, AppColors.error)),
          ],
        ),
        const SizedBox(height: 32),

        // Chart & System Log panel
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue line chart
            Expanded(
              flex: 2,
              child: GlassCard(
                borderRadius: 20,
                opacity: 0.04,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform Revenue Trends', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Weekly platform fees commissions generated.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (value >= 0 && value < 7) {
                                    return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 3000),
                                FlSpot(1, 4500),
                                FlSpot(2, 3800),
                                FlSpot(3, 6200),
                                FlSpot(4, 5500),
                                FlSpot(5, 7800),
                                FlSpot(6, 9200),
                              ],
                              isCurved: true,
                              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    AppColors.secondary.withOpacity(0.01),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),

            // System specs & health log
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                opacity: 0.04,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Server Specifications', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildLogTile('Database Engine', 'MongoDB Atlas v6.0', true),
                    _buildLogTile('Media Storage', 'Cloudinary CDN (Cloud)', true),
                    _buildLogTile('Server Latency', '42 ms (Stable)', true),
                    _buildLogTile('Daily Active sessions', '2,408 Sessions', false),
                    const SizedBox(height: 24),
                    const Text(
                      'All nodes are operating fully within specifications. Memory leaks and database loads are below thresholds.',
                      style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildWebKpiCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      opacity: 0.05,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(String label, String value, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (isHealthy) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.success, size: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WEB TAB: NOTES AUDIT QUEUE
  // ==========================================
  Widget _buildWebNotesAudit(bool isDark) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.04,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document Moderation Queue', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Review uploaded files to check content accuracy before listing.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingApprovals.length} Pending Notes',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _pendingApprovals.isEmpty
              ? _buildEmptyState(isDark)
              : Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(2),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Document Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Text('Author / College', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Price Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Date Uploaded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    // Table Rows
                    ...List.generate(_pendingApprovals.length, (index) {
                      final item = _pendingApprovals[index];
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text('${item['author']}\n${item['college']}', style: const TextStyle(fontSize: 12, height: 1.4)),
                          Text(item['price'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(item['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _rejectDocument(index),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Reject', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _approveDocument(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ==========================================
  // WEB TAB: USER DIRECTORY
  // ==========================================
  Widget _buildWebUserDirectory(bool isDark) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.04,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registered Users Directory', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Manage student and teacher access credentials, inspect balances.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              // Search Input Box
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchQueryController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 16),
                    hintText: 'Search users...',
                    isDense: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.8),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(2.3),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Text('System Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('College Affiliation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Notes Uploads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Coin Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              // Filtered User Rows
              ..._usersList.asMap().entries.where((entry) {
                final query = _searchQueryController.text.toLowerCase();
                if (query.isEmpty) return true;
                final name = entry.value['name'].toString().toLowerCase();
                final email = entry.value['email'].toString().toLowerCase();
                return name.contains(query) || email.contains(query);
              }).map((entry) {
                final idx = entry.key;
                final user = entry.value;
                final isBanned = user['isBanned'] as bool;
                
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(user['name'][0], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(user['email'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      user['role'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: user['role'] == 'Teacher' ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                    Text(user['college'], style: const TextStyle(fontSize: 12)),
                    Text('${user['notes']} uploads', style: const TextStyle(fontSize: 12)),
                    Text('${user['coins']} Coins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // Show adjust coins dialog box
                            _showCoinsDialog(context, idx, user['coins']);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Coins', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _toggleUserBan(idx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBanned ? AppColors.success : AppColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: Text(
                            isBanned ? 'Unban' : 'Suspend',
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showCoinsDialog(BuildContext context, int index, int currentCoins) {
    final controller = TextEditingController(text: '$currentCoins');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Adjust Coin Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Modify balance for ${_usersList[index]['name']}.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Coins Count',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCoins = int.tryParse(controller.text) ?? currentCoins;
                _adjustUserCoins(index, newCoins);
                Navigator.pop(ctx);
              },
              child: const Text('Apply Changes'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // WEB TAB: SYSTEM SETTINGS
  // ==========================================
  Widget _buildWebSettings(bool isDark) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.04,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Parameters & Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Configure marketplace fee deductions, wallet credits, and audit preferences.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 32),

          // Platform Commission rate
          const Text('Platform Transaction Fee (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _commissionRate,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  label: '${_commissionRate.toInt()}%',
                  onChanged: (val) {
                    setState(() {
                      _commissionRate = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_commissionRate.toInt()}% Platform Cut',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Sign-up Bonus Coins
          const Text('User Registration Bonus (Coins)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _signupReward > 0
                    ? () => setState(() => _signupReward -= 10)
                    : null,
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text('$_signupReward', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _signupReward += 10),
              ),
              const SizedBox(width: 16),
              const Text('Given as signup credit bonus to students', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 28),

          // Safety moderation modes
          const Divider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manual Document Auditing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Force manual admin approval before publishing any notes.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Switch(
                value: _manualVerificationOnly,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _manualVerificationOnly = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save button mockup
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System configurations saved successfully!'), backgroundColor: AppColors.success),
              );
            },
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            label: const Text('Save Parameters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }


  // ==========================================
  // MOBILE / PHONE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Section
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildMobileKpiCard('Revenue', '₹24.5k', Icons.account_balance_wallet_rounded, AppColors.primary),
                  _buildMobileKpiCard('Users', '12.4k', Icons.groups_rounded, AppColors.secondary),
                  _buildMobileKpiCard('Pending', '${_pendingApprovals.length}', Icons.fact_check_rounded, Colors.amber),
                  _buildMobileKpiCard('Issues', '4', Icons.report_problem_rounded, AppColors.error),
                ],
              ),
              const SizedBox(height: 28),

              // Pending Audits title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notes Approval Queue',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${_pendingApprovals.length} items',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _pendingApprovals.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingApprovals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _pendingApprovals[index];
                        return GlassCard(
                          borderRadius: 16,
                          opacity: 0.05,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'By: ${item['author']} • ${item['college']} • Price: ${item['price']}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _rejectDocument(index),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _approveDocument(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileKpiCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 14,
      opacity: 0.04,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.success.withOpacity(0.6)),
            const SizedBox(height: 12),
            const Text('Approval Queue Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('All uploaded notes are active.', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}