import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/utils/file_download_helper.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  int _xp = 0;
  bool _dailyClaimed = false;
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  
  final List<String> _cart = [];
  final List<String> _wishlist = [];
  List<dynamic> _realOrders = [];
  List<dynamic> _realWithdrawals = [];
  bool _loading = false;
  List<String> _userBadges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDataFromBackend();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _couponCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromBackend() async {
    if (mounted) setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;

      final dio = Dio();
      final headers = {'Authorization': 'Bearer $token'};

      // 1. Fetch user profile (coins, badges)
      final meRes = await dio.get('$backendBaseUrl/auth/me', options: Options(headers: headers));
      if (meRes.statusCode == 200 && meRes.data['success'] == true) {
        final u = meRes.data['user'];
        _coins = ((u['coins'] ?? 0) as num).toInt();
        _userBadges = List<String>.from(u['badges'] ?? []);
        _dailyClaimed = _userBadges.contains('DailyEarner');
        _xp = (_userBadges.length * 100) + (_coins * 5);
      }

      // 2. Fetch orders
      final ordersRes = await dio.get('$backendBaseUrl/orders', options: Options(headers: headers));
      if (ordersRes.statusCode == 200 && ordersRes.data['success'] == true) {
        _realOrders = ordersRes.data['data'] ?? [];
      }

      // 3. Fetch withdrawals
      final withdrawalsRes = await dio.get('$backendBaseUrl/wallet/withdrawals', options: Options(headers: headers));
      if (withdrawalsRes.statusCode == 200 && withdrawalsRes.data['success'] == true) {
        _realWithdrawals = withdrawalsRes.data['data'] ?? [];
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading buyer dashboard data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _purchasedNotes {
    return _realOrders.where((o) => o['note'] != null && o['note']['itemType'] == 'Digital').map((o) => o['note']).toList();
  }

  List<Map<String, String>> get _transactionsList {
    final List<Map<String, String>> txs = [];
    // Base SignUp Reward if badges exist
    if (_userBadges.isNotEmpty) {
      txs.add({
        'title': 'Sign Up Welcome Reward',
        'amount': '+100 Coins',
        'date': 'Account Start',
        'type': 'credit',
      });
    }
    if (_dailyClaimed) {
      txs.add({
        'title': 'Daily Check-in Reward',
        'amount': '+10 +25 XP',
        'date': 'Today',
        'type': 'credit',
      });
    }
    for (var o in _realOrders) {
      final noteTitle = o['note']?['title'] ?? 'Purchase';
      final price = o['price'] ?? 0;
      final date = o['createdAt'] != null ? o['createdAt'].toString().split('T').first : 'Recent';
      txs.add({
        'title': 'Bought "$noteTitle"',
        'amount': '-$price Coins',
        'date': date,
        'type': 'debit',
      });
    }
    for (var w in _realWithdrawals) {
      final amount = w['amount'] ?? 0;
      final status = w['status'] ?? 'Pending';
      final date = w['createdAt'] != null ? w['createdAt'].toString().split('T').first : 'Recent';
      txs.add({
        'title': 'Cash Withdrawal ($status)',
        'amount': '-$amount Coins',
        'date': date,
        'type': 'debit',
      });
    }
    return txs;
  }

  Future<void> _claimDailyCoins() async {
    if (_dailyClaimed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;

      final dio = Dio();
      final res = await dio.post(
        '$backendBaseUrl/wallet/daily-reward',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _coins = ((res.data['coins'] ?? _coins + 10) as num).toInt();
          _dailyClaimed = true;
          _userBadges = List<String>.from(res.data['badges'] ?? _userBadges);
          _xp += 25;
        });
        _showSnack('Claimed 10 Daily Reward Coins + 25 XP!');
        await prefs.setInt('user_coins', _coins);
      }
    } catch (e) {
      debugPrint('Error claiming daily coins: $e');
      _showSnack('Failed to claim daily reward.');
    }
  }

  Future<void> _claimReferral() async {
    if (_refCtrl.text.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;

      final dio = Dio();
      final res = await dio.post(
        '$backendBaseUrl/wallet/referral',
        data: {'code': _refCtrl.text},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _coins = ((res.data['currentCoins'] ?? _coins + 50) as num).toInt();
          _xp += 50;
        });
        _showSnack('Referral Code applied! Credited 50 Coins.');
        _refCtrl.clear();
        await prefs.setInt('user_coins', _coins);
      } else {
        _showSnack(res.data['message'] ?? 'Failed to apply referral code.');
      }
    } catch (e) {
      debugPrint('Error applying referral: $e');
      _showSnack('Failed to apply referral code.');
    }
  }

  void _applyCoupon() {
    if (_couponCtrl.text.toUpperCase() == 'EDUSTART') {
      _showSnack('Coupon "EDUSTART" applied! 20% discount activated.');
    } else {
      _showSnack('Invalid Coupon Code.');
    }
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

  Future<void> _downloadFile(String fileUrl, String title, String noteId) async {
    await FileDownloadHelper.downloadAndOpen(fileUrl, title, noteId, _showSnack);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buyer Central Hub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Learning'),
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Gamify'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Wallet'),
            Tab(icon: Icon(Icons.shopping_cart_rounded), text: 'Cart'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildLearningTab(isDark),
                  _buildGamifyTab(isDark),
                  _buildWalletTab(isDark),
                  _buildCartTab(isDark),
                ],
              ),
      ),
    );
  }

  // ── Tab 1: My Learning ──────────────────────────────────────────
  Widget _buildLearningTab(bool isDark) {
    final purchased = _purchasedNotes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchased Notes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          purchased.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text('No purchased notes yet.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: purchased.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = purchased[index];
                    final title = note['title'] ?? 'Untitled';
                    final subject = note['subject'] ?? 'General';
                    final fileUrl = note['fileUrl'] ?? '';
                    final noteId = note['_id'] ?? '';
                    return GlassCard(
                      borderRadius: 14,
                      opacity: 0.04,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('$subject • Download active', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.primary),
                            onPressed: () => _downloadFile(fileUrl, title, noteId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 28),
          Text('My Wishlist', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _wishlist.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text('Wishlist is empty.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wishlist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return GlassCard(
                      borderRadius: 14,
                      opacity: 0.04,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppColors.error),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_wishlist[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Text('IIT Bombay • Price Drop Alert active', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                            onPressed: () => context.push('/search'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ── Tab 2: Gamification ─────────────────────────────────────────
  Widget _buildGamifyTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP & Level Card
          GlassCard(
            borderRadius: 20,
            opacity: 0.08,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rank Level ${(_xp / 100).floor() + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('XP Progress to next level', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                    Text('$_xp / 1000 XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_xp % 100) / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ).animate().slideY(duration: 400.ms, begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // Daily Claim coins
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _dailyClaimed ? null : _claimDailyCoins,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(_dailyClaimed ? 'Daily Reward Claimed' : 'Claim Daily Check-in (+10 Coins)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text('Earned Badges', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _badgeBox('Scholar', 'First Purchase', Icons.school_rounded, _purchasedNotes.isNotEmpty ? AppColors.primary : Colors.grey),
              _badgeBox('Daily Check', 'Check in daily', Icons.calendar_today_rounded, _dailyClaimed ? AppColors.success : Colors.grey),
              _badgeBox('Reviewer', 'First Review', Icons.rate_review_rounded, AppColors.accent),
              _badgeBox('Referral Star', 'Invite a Friend', Icons.people_rounded, _userBadges.contains('Influencer') ? AppColors.warning : Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeBox(String name, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── Tab 3: Wallet & Referral ────────────────────────────────────
  Widget _buildWalletTab(bool isDark) {
    final txs = _transactionsList;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coins balance display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text('$_coins Coins', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('1 Coin = ₹1 conversion rate. Cashable upon withdraw.', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Referral application box
          Text('Have an Invite Code?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter referral code',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _claimReferral,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text('Transaction History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          txs.isEmpty
              ? const Center(child: Text('No transaction history found.'))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = txs[index];
                    final isCredit = t['type'] == 'credit';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(t['date']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Text(
                        t['amount']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCredit ? AppColors.success : AppColors.error,
                        ),
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // ── Tab 4: Cart tab ─────────────────────────────────────────────
  Widget _buildCartTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Your shopping cart is empty.'))
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return GlassCard(
                        borderRadius: 14,
                        opacity: 0.04,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_cart[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Text('IIT Bombay • ₹149', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _cart.removeAt(index);
                                });
                                _showSnack('Removed item from cart.');
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 32),

          // Coupon application input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Promo / Coupon code (EDUSTART)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Checkout CTA
          ElevatedButton(
            onPressed: _cart.isEmpty
                ? null
                : () {
                    setState(() {
                      _cart.clear();
                    });
                    _showSnack('Checkout completed successfully using wallet coins/UPI.');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Secure Checkout', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
