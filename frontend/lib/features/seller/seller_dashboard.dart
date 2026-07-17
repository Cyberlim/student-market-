import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Coupon state
  final TextEditingController _couponCodeCtrl = TextEditingController();
  final TextEditingController _couponDiscountCtrl = TextEditingController();
  List<Map<String, String>> _coupons = [];
  bool _loadingCoupons = false;

  // Withdrawal requests
  List<Map<String, dynamic>> _withdrawals = [];
  bool _loadingWithdrawals = false;

  // Real orders from backend
  List<Map<String, dynamic>> _orders = [];
  bool _loadingOrders = true;

  // Notifications
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _loadingNotifs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchSellerOrders();
    _fetchNotifications();
    _fetchCoupons();
    _fetchWithdrawals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _couponCodeCtrl.dispose();
    _couponDiscountCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  Future<void> _fetchSellerOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/orders/seller',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        setState(() {
          _orders = raw.map((o) {
            final note = o['note'] ?? {};
            final buyer = o['buyer'] ?? {};
            final pickupDate = o['pickupDate'];
            return {
              'id': o['_id'] ?? '',
              'buyer': buyer['name'] ?? 'Unknown Buyer',
              'note': note['title'] ?? 'Item',
              'price': '₹${o['price'] ?? 0}',
              'coinsUsed': o['coinsUsed'] ?? 0,
              'cashPaid': o['cashPaid'] ?? 0,
              'status': o['status'] ?? 'Pending',
              'itemType': note['itemType'] ?? 'Digital',
              'date': _formatDate(o['createdAt']),
              'pickupDate': pickupDate != null ? _formatDate(pickupDate) : null,
              'thumbnailUrl': note['thumbnailUrl'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loadingNotifs = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
          _unreadCount = response.data['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) setState(() => _loadingNotifs = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final token = await _getToken();
      final dio = Dio();
      await dio.put(
        '$backendBaseUrl/notifications/read-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      setState(() {
        _unreadCount = 0;
        for (var n in _notifications) n['isRead'] = true;
      });
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _fetchCoupons() async {
    if (mounted) setState(() => _loadingCoupons = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/coupons',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        setState(() {
          _coupons = raw.map<Map<String, String>>((c) => {
            'code': (c['code'] ?? '').toString(),
            'discount': '${c['discountPercent']}%',
            'status': c['active'] == true ? 'Active' : 'Inactive',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
    } finally {
      if (mounted) setState(() => _loadingCoupons = false);
    }
  }

  Future<void> _fetchWithdrawals() async {
    if (mounted) setState(() => _loadingWithdrawals = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/wallet/withdrawals',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        setState(() {
          _withdrawals = raw.map<Map<String, dynamic>>((w) {
            final String status = w['status'] ?? 'Pending';
            Color statusColor = Colors.amber;
            if (status == 'Approved') statusColor = AppColors.success;
            if (status == 'Rejected') statusColor = AppColors.error;
            return {
              'amount': '₹${w['amount'] ?? 0}',
              'date': w['createdAt'] != null ? w['createdAt'].toString().split('T').first : 'N/A',
              'status': status,
              'color': statusColor,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching withdrawals: $e');
    } finally {
      if (mounted) setState(() => _loadingWithdrawals = false);
    }
  }

  Future<void> _createCoupon() async {
    if (_couponCodeCtrl.text.isEmpty || _couponDiscountCtrl.text.isEmpty) return;
    try {
      final token = await _getToken();
      final dio = Dio();
      final discount = int.tryParse(_couponDiscountCtrl.text) ?? 10;
      final response = await dio.post(
        '$backendBaseUrl/coupons',
        data: {
          'code': _couponCodeCtrl.text.toUpperCase(),
          'discountPercent': discount,
          'maxDiscount': 1000,
          'expiryDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        _showSnack('Coupon ${_couponCodeCtrl.text.toUpperCase()} created successfully!');
        _couponCodeCtrl.clear();
        _couponDiscountCtrl.clear();
        _fetchCoupons();
      }
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      _showSnack('Failed to create coupon.');
    }
  }

  Future<void> _submitWithdrawal(double amount, String acc, String ifsc, String name) async {
    try {
      final token = await _getToken();
      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/wallet/withdraw',
        data: {
          'amount': amount,
          'accountNumber': acc,
          'ifscCode': ifsc,
          'accountHolderName': name,
          'bankName': 'Campus Bank',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201) {
        _showSnack('Withdrawal request of ₹${amount.toInt()} submitted.');
        _fetchWithdrawals();
      }
    } catch (e) {
      debugPrint('Error submitting withdrawal: $e');
      _showSnack('Failed to submit withdrawal request.');
    }
  }

  void _showWithdrawalSheet() {
    final amountCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: 30,
          blur: 20,
          opacity: 0.12,
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          margin: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Request Bank Transfer', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name')),
                const SizedBox(height: 8),
                TextFormField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Account Number')),
                const SizedBox(height: 8),
                TextFormField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),
                const SizedBox(height: 8),
                TextFormField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (INR ₹)')),
                const SizedBox(height: 20),
                GradientButton(
                  text: 'Submit Request',
                  onPressed: () {
                    Navigator.pop(context);
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amt >= 100) {
                      _submitWithdrawal(amt, accCtrl.text, ifscCtrl.text, nameCtrl.text);
                    } else {
                      _showSnack('Minimum withdrawal amount is ₹100.');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNotificationsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.3,
          builder: (ctx, scroll) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Notifications', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_unreadCount > 0)
                          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingNotifs
                        ? const Center(child: CircularProgressIndicator())
                        : _notifications.isEmpty
                            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text('No notifications yet', style: GoogleFonts.poppins(color: Colors.grey)),
                              ]))
                            : ListView.separated(
                                controller: scroll,
                                itemCount: _notifications.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final n = _notifications[i];
                                  final isRead = n['isRead'] == true;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isRead ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.15),
                                      child: Icon(
                                        n['type'] == 'Order' ? Icons.shopping_bag_rounded : Icons.notifications_rounded,
                                        color: isRead ? Colors.grey : AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(n['title'] ?? '', style: GoogleFonts.poppins(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                                    subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    trailing: Text(_formatDate(n['createdAt']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    tileColor: isRead ? null : AppColors.primary.withValues(alpha: 0.04),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derived stats from real orders
    final totalRevenue = _orders.fold<double>(0, (sum, o) {
      final p = o['price']?.toString().replaceAll('₹', '') ?? '0';
      return sum + (double.tryParse(p) ?? 0);
    });
    final orderCount = _orders.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Notifications bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
                tooltip: 'Notifications',
                onPressed: () => _showNotificationsSheet(isDark),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded, color: AppColors.primary),
            tooltip: 'Upload Note',
            onPressed: () => context.push('/notes/upload'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Orders'),
            Tab(icon: Icon(Icons.local_offer_rounded), text: 'Coupons'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Payouts'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStatsTab(isDark, totalRevenue, orderCount),
            _buildOrdersTab(isDark),
            _buildCouponsTab(isDark),
            _buildPayoutsTab(isDark),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Stats & Line Chart ──────────────────────────────────────
  Widget _buildStatsTab(bool isDark, double totalRevenue, int orderCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.green),
              _buildStatCard('Orders', '$orderCount', Icons.receipt_long_rounded, AppColors.primary),
              _buildStatCard('Unread Notifs', '$_unreadCount', Icons.notifications_rounded, Colors.orange),
              _buildStatCard('Conversion', '4.2%', Icons.trending_up_rounded, Colors.amber),
            ],
          ),
          const SizedBox(height: 28),
          Text('Revenue Performance', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 20, top: 12),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() < months.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(months[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 500), FlSpot(1, 1200), FlSpot(2, 800),
                      FlSpot(3, 2400), FlSpot(4, 1900), FlSpot(5, 4590),
                    ],
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          // Recent activity from real notifications
          if (_notifications.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Recent Activity', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._notifications.take(3).map((n) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.shopping_bag_rounded, size: 16, color: AppColors.primary),
              ),
              title: Text(n['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_formatDate(n['createdAt']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      opacity: 0.05,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Tab 2: Orders Log (real data) ──────────────────────────────────
  Widget _buildOrdersTab(bool isDark) {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No orders yet', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Orders from buyers will appear here', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchSellerOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final isPhysical = order['itemType'] == 'Physical';
          final pickupDate = order['pickupDate'];
          final coinsUsed = order['coinsUsed'] as int? ?? 0;
          final status = order['status'] as String? ?? 'Pending';

          Color statusColor = Colors.grey;
          if (status == 'Completed' || status == 'Delivered') statusColor = AppColors.success;
          else if (status == 'Pending') statusColor = Colors.orange;
          else if (status == 'Dispatched') statusColor = Colors.blue;
          else if (status == 'Out for Delivery') statusColor = Colors.purple;

          return GlassCard(
            borderRadius: 16,
            opacity: 0.05,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        (order['buyer'] as String? ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['buyer'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(order['note'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(order['price'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                        Text(order['date'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    if (isPhysical)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Physical', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    if (coinsUsed > 0) ...[
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 13),
                        Text(' $coinsUsed coins', style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ],
                ),
                // Pickup Date
                if (isPhysical) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        pickupDate != null ? 'Pickup: $pickupDate' : 'Pickup date: Pending from admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: pickupDate != null ? AppColors.success : Colors.grey,
                          fontWeight: pickupDate != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tab 3: Coupons ─────────────────────────────────────────────────
  Widget _buildCouponsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generate Coupon Code', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: _couponCodeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code (e.g. DISCOUNT30)')),
          const SizedBox(height: 10),
          TextField(controller: _couponDiscountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount Percentage (%)')),
          const SizedBox(height: 16),
          GradientButton(text: 'Generate Code', onPressed: _createCoupon),
          const SizedBox(height: 28),
          Text('Active Coupons', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = _coupons[index];
              return ListTile(
                title: Text(c['code']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Discount: ${c['discount']}'),
                trailing: Chip(label: Text(c['status']!, style: const TextStyle(fontSize: 10))),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Payouts ─────────────────────────────────────────────────
  Widget _buildPayoutsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('₹${_orders.fold<double>(0, (s, o) => s + (double.tryParse(o['price']?.toString().replaceAll('₹', '') ?? '0') ?? 0)).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Available to withdraw', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(text: '💸 Request Withdrawal', onPressed: _showWithdrawalSheet),
          const SizedBox(height: 24),
          Text('Withdrawal History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._withdrawals.map((w) => ListTile(
            leading: CircleAvatar(backgroundColor: (w['color'] as Color).withValues(alpha: 0.15), child: Icon(Icons.arrow_upward_rounded, color: w['color'] as Color)),
            title: Text(w['amount']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(w['date']!),
            trailing: Chip(
              label: Text(w['status']!, style: const TextStyle(fontSize: 10)),
              backgroundColor: (w['color'] as Color).withValues(alpha: 0.15),
            ),
          )),
        ],
      ),
    );
  }
}
