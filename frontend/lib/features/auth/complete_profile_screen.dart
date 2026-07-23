import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/gradient_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  String _selectedRole = 'Student';
  bool _loading = false;

  final List<String> _departments = [
    'Computer Science', 'Electronics & Communication', 'Mechanical Engineering',
    'Civil Engineering', 'Information Technology', 'Electrical Engineering',
    'Chemical Engineering', 'Biotechnology', 'Mathematics', 'Physics',
    'Commerce', 'Management', 'Arts', 'Other',
  ];

  final List<String> _roles = ['Student', 'Teacher'];

  @override
  void initState() {
    super.initState();
    _prefillFromPrefs();
  }

  Future<void> _prefillFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('user_name') ?? '';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final dio = Dio();
      final response = await dio.put(
        '$backendBaseUrl/auth/profile',
        data: {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'college': _collegeCtrl.text.trim(),
          'department': _selectedDepartment,
          'role': _selectedRole,
          'bio': _bioCtrl.text.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = response.data['user'];
        await prefs.setString('user_name', user['name'] ?? '');
        await prefs.setString('user_email', user['email'] ?? '');
        await prefs.setString('user_avatar', user['avatar'] ?? '');
        await prefs.setString('user_college', user['college'] ?? '');
        await prefs.setString('user_department', user['department'] ?? '');
        await prefs.setString('user_phone', user['phone'] ?? '');
        await prefs.setString('user_role', user['role'] ?? 'Student');
        await prefs.setInt('user_coins', ((user['coins'] ?? 100) as num).toInt());
        await prefs.setBool('profile_complete', true);

        if (mounted) {
          context.go('/');
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      _snack('Error: $msg');
    } catch (e) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.school_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us a little about yourself to get started on EduMarket.',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                Text('Full Name *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration('e.g. Alok Thakur', Icons.person_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 18),

                // Phone
                Text('Phone Number *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('e.g. 9876543210', Icons.phone_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (v.trim().length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // College
                Text('College / University *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _collegeCtrl,
                  decoration: _inputDecoration('e.g. IIT Bombay', Icons.account_balance_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'College name is required' : null,
                ),
                const SizedBox(height: 18),

                // Department
                Text('Department *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _buildDropdown(
                  value: _selectedDepartment,
                  items: _departments,
                  icon: Icons.category_rounded,
                  onChanged: (v) => setState(() => _selectedDepartment = v!),
                ),
                const SizedBox(height: 18),

                // Role
                Text('I am a *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: _roles.map((r) {
                    final isSelected = _selectedRole == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: r == 'Student' ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : (isDark ? Colors.white12 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                r == 'Student' ? Icons.menu_book_rounded : Icons.cast_for_education_rounded,
                                color: isSelected ? Colors.white : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(r, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Bio (optional)
                Text('Short Bio (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration('Tell others about yourself...', Icons.edit_note_rounded),
                ),
                const SizedBox(height: 32),

                GradientButton(
                  text: _loading ? 'Saving...' : 'Complete Profile & Continue →',
                  onPressed: _loading ? () {} : _submit,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
