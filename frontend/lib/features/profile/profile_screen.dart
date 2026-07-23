import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:notes_marketplace/main.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _darkMode = false;
  String _userName = '';
  String _userEmail = '';
  String _userAvatar = '';
  String _userCollege = '';
  String _userDepartment = '';
  String _userPhone = '';
  String _userBio = '';
  String _userRole = 'Student';
  int _userCoins = 0;
  bool _loadingProfile = true;
  int _followersCount = 0;
  int _followingCount = 0;
  String _selectedLanguage = 'English (US)';

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  Future<void> _loadFromBackend() async {
    setState(() => _loadingProfile = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) {
        await _loadFromPrefs();
        return;
      }
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final u = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        // Sync to prefs
        await prefs.setString('user_name', u['name'] ?? '');
        await prefs.setString('user_email', u['email'] ?? '');
        await prefs.setString('user_avatar', u['avatar'] ?? '');
        await prefs.setString('user_college', u['college'] ?? '');
        await prefs.setString('user_department', u['department'] ?? '');
        await prefs.setString('user_phone', u['phone'] ?? '');
        await prefs.setString('user_bio', u['bio'] ?? '');
        await prefs.setString('user_role', u['role'] ?? 'Student');
        await prefs.setInt('user_coins', ((u['coins'] ?? 0) as num).toInt());
        final followersList = u['followers'] as List?;
        final followingList = u['following'] as List?;
        final followersCount = followersList?.length ?? 0;
        final followingCount = followingList?.length ?? 0;
        await prefs.setInt('user_followers', followersCount);
        await prefs.setInt('user_following', followingCount);
        if (mounted) {
          setState(() {
            _userName = u['name'] ?? '';
            _userEmail = u['email'] ?? '';
            _userAvatar = u['avatar'] ?? '';
            _userCollege = u['college'] ?? '';
            _userDepartment = u['department'] ?? '';
            _userPhone = u['phone'] ?? '';
            _userBio = u['bio'] ?? '';
            _userRole = u['role'] ?? 'Student';
            _userCoins = ((u['coins'] ?? 0) as num).toInt();
            _followersCount = followersCount;
            _followingCount = followingCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile from backend: $e');
      await _loadFromPrefs();
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? '';
        _userEmail = prefs.getString('user_email') ?? '';
        _userAvatar = prefs.getString('user_avatar') ?? '';
        _userCollege = prefs.getString('user_college') ?? '';
        _userDepartment = prefs.getString('user_department') ?? '';
        _userPhone = prefs.getString('user_phone') ?? '';
        _userBio = prefs.getString('user_bio') ?? '';
        _userRole = prefs.getString('user_role') ?? 'Student';
        _userCoins = prefs.getInt('user_coins') ?? 0;
        _followersCount = prefs.getInt('user_followers') ?? 0;
        _followingCount = prefs.getInt('user_following') ?? 0;
        _selectedLanguage = prefs.getString('user_language') ?? 'English (US)';
      });
    }
  }

  void _openLanguageSelector() {
    final languages = ['English (US)', 'Hindi (हिंदी)', 'Tamil (தமிழ்)', 'Spanish (Español)'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Display Language', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected = lang.startsWith(_selectedLanguage.split(' ').first);
                return ListTile(
                  title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_language', lang);
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language set to $lang')));
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _openFAQSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Help & Support FAQ', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFaqItem('How do I upload study notes?', 'Click the "+" action button above the bottom navigation bar. Complete the listing form with title, subject, and college details.'),
                    const SizedBox(height: 12),
                    _buildFaqItem('How are campus store items approved?', 'Physical listings require admin approval. After uploading photos and prices, items are reviewed and published once approved.'),
                    const SizedBox(height: 12),
                    _buildFaqItem('Are the transactions secure?', 'Yes. Purchases are verified with database keys. Coins are deducted from buyers and credited to sellers instantly.'),
                    const SizedBox(height: 12),
                    _buildFaqItem('How do I contact support?', 'Reach out at developer@edumarket.edu for billing, disputes, or technical issues.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.5))],
      ),
    );
  }

  // ── Edit Profile Sheet ─────────────────────────────────────────────
  void _showEditProfileSheet(bool isDark) {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);
    final collegeCtrl = TextEditingController(text: _userCollege);
    final bioCtrl = TextEditingController(text: _userBio);
    String dept = _userDepartment.isNotEmpty ? _userDepartment : 'Computer Science';
    String role = _userRole;
    bool saving = false;

    final departments = [
      'Computer Science', 'Electronics & Communication', 'Mechanical Engineering',
      'Civil Engineering', 'Information Technology', 'Electrical Engineering',
      'Chemical Engineering', 'Biotechnology', 'Mathematics', 'Physics',
      'Commerce', 'Management', 'Arts', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                builder: (ctx, scroll) => ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Handle
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),

                    Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Name
                    _sheetField('Full Name', nameCtrl, Icons.person_rounded, isDark),
                    const SizedBox(height: 14),
                    // Phone
                    _sheetField('Phone Number', phoneCtrl, Icons.phone_rounded, isDark, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    // College
                    _sheetField('College / University', collegeCtrl, Icons.account_balance_rounded, isDark),
                    const SizedBox(height: 14),

                    // Department
                    Text('Department', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: departments.contains(dept) ? dept : departments.first,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (v) => setSheet(() => dept = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role
                    Text('Role', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Student', 'Teacher'].map((r) {
                        final sel = role == r;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(() => role = r),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(right: r == 'Student' ? 10 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: sel ? AppColors.primaryGradient : null,
                                color: sel ? null : (isDark ? Colors.white12 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(child: Text(r, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.grey))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Bio
                    _sheetField('Bio (Optional)', bioCtrl, Icons.edit_note_rounded, isDark, maxLines: 3),
                    const SizedBox(height: 24),

                    GradientButton(
                      text: saving ? 'Saving...' : 'Save Changes',
                      onPressed: saving ? () {} : () async {
                        setSheet(() => saving = true);
                        try {
                          final token = await _getToken();
                          final dio = Dio();
                          final response = await dio.put(
                            '$backendBaseUrl/auth/profile',
                            data: {
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'college': collegeCtrl.text.trim(),
                              'department': dept,
                              'role': role,
                              'bio': bioCtrl.text.trim(),
                            },
                            options: Options(headers: {'Authorization': 'Bearer $token'}),
                          );
                          if (response.statusCode == 200 && response.data['success'] == true) {
                            final u = response.data['user'];
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('user_name', u['name'] ?? '');
                            await prefs.setString('user_college', u['college'] ?? '');
                            await prefs.setString('user_department', u['department'] ?? '');
                            await prefs.setString('user_phone', u['phone'] ?? '');
                            await prefs.setString('user_bio', u['bio'] ?? '');
                            await prefs.setString('user_role', u['role'] ?? 'Student');
                            if (mounted) {
                              setState(() {
                                _userName = u['name'] ?? _userName;
                                _userCollege = u['college'] ?? _userCollege;
                                _userDepartment = u['department'] ?? _userDepartment;
                                _userPhone = u['phone'] ?? _userPhone;
                                _userBio = u['bio'] ?? _userBio;
                                _userRole = u['role'] ?? _userRole;
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profile updated ✅', style: GoogleFonts.poppins(color: Colors.white)),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        } on DioException catch (e) {
                          final msg = e.response?.data?['message'] ?? e.message;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
                        } finally {
                          setSheet(() => saving = false);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, IconData icon, bool isDark, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    _darkMode = isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _loadFromBackend,
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUserBanner(isDark),
                    const SizedBox(height: 16),
                    _buildCoinsCard(isDark),
                    const SizedBox(height: 28),
                    Text('Dashboard Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildDashboardShortcuts(context, isDark),
                    const SizedBox(height: 28),
                    Text('General Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildGeneralSettings(isDark),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (mounted) context.go('/auth/login');
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserBanner(bool isDark) {
    return GlassCard(
      borderRadius: 24,
      opacity: 0.05,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: _userAvatar.isNotEmpty ? NetworkImage(_userAvatar) : null,
                child: _userAvatar.isEmpty
                    ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName.isNotEmpty ? _userName : 'Your Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 2),
                Text(_userEmail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (_userCollege.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.school_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text('$_userCollege • $_userDepartment', style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ]),
                ],
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_userRole, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('$_followersCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text(' Followers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text('$_followingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text(' Following', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileSheet(isDark),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet Coins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('$_userCoins coins', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Use coins to buy notes & campus items', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 20),
              Text(
                _userCoins >= 500 ? 'Gold' : _userCoins >= 200 ? 'Silver' : 'Bronze',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardShortcuts(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildListTile(icon: Icons.storefront_rounded, color: AppColors.primary, title: 'Seller Analytics Board', subtitle: 'Upload files and track earned revenue.', onTap: () => context.push('/seller')),
        const SizedBox(height: 12),
        _buildListTile(icon: Icons.local_library_rounded, color: AppColors.secondary, title: 'Student Learning Panel', subtitle: 'Access purchased notes and badges.', onTap: () => context.push('/buyer')),
        const SizedBox(height: 12),
        _buildListTile(icon: Icons.local_shipping_rounded, color: AppColors.success, title: 'My Purchase Orders & Tracking', subtitle: 'Track shipment status of campus item orders.', onTap: () => context.push('/orders')),
      ],
    );
  }

  Widget _buildGeneralSettings(bool isDark) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.04,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SwitchListTile(
            value: _darkMode,
            activeColor: AppColors.primary,
            title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Adjust appearance for low-light.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
            onChanged: (val) => ref.read(themeNotifierProvider.notifier).toggleTheme(val),
          ),
          const Divider(indent: 56, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.secondary),
            title: const Text('Display Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _openLanguageSelector,
          ),
          const Divider(indent: 56, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.location_on_rounded, color: AppColors.primary),
            title: const Text('Saved Shipping Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Manage your delivery coordinates.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push('/profile/addresses'),
          ),
          const Divider(indent: 56, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.help_center_rounded, color: AppColors.accent),
            title: const Text('Help & Support FAQ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _openFAQSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GlassCard(
      borderRadius: 16,
      opacity: 0.04,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
