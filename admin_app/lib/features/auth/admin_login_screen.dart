import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@edumarket.in');
  final _passCtrl  = TextEditingController(text: 'admin123');
  bool  _obscure  = true;
  bool  _loading  = false;
  String? _error;

  void _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await AdminApiService.request(
        'POST',
        '/api/auth/login',
        data: {
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        },
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        // Check if user has Admin role
        final user = response.data['user'] ?? {};
        if (user['role'] != 'Admin') {
          setState(() {
            _error = 'Access denied. This account does not have Admin privileges.';
            _loading = false;
          });
          return;
        }

        // Store JWT token for authenticated API calls
        final token = response.data['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // Register FCM token now that admin is logged in
          AdminNotificationService.instance.registerFcmToken();
        }

        if (mounted) context.go('/');
      } else {
        final msg = response?.data?['message'] ?? 'Login failed. Please try again.';
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Make sure the backend server is running.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return isMobile ? _buildMobile() : _buildDesktop();
        },
      ),
    );
  }

  // ── Mobile ────────────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(28, 64, 28, 36),
            decoration: const BoxDecoration(
              gradient: kPrimaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text('EduMarket Admin',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    )),
                const SizedBox(height: 6),
                Text('Secure admin control panel. Authorized access only.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    )),
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: _buildFormFields(),
          ),
        ],
      ),
    );
  }

  // ── Desktop ───────────────────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          child: Container(
            decoration: const BoxDecoration(gradient: kPrimaryGradient),
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 32),
                Text('EduMarket\nAdmin Console',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      height: 1.2,
                    )).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                const SizedBox(height: 16),
                Text('Secure control panel for managing the\nEduMarket notes marketplace platform.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.6,
                    )).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 48),
                ...['Notes moderation & approval queue',
                    'User account management & analytics',
                    'Platform revenue & fee configuration',
                    'Dispute resolution & content reports']
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 10),
                            Text(t, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          ]),
                        )),
              ],
            ),
          ),
        ),

        // Right login panel
        Container(
          width: 460,
          color: kSurface,
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Admin Sign In',
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  )),
              const SizedBox(height: 8),
              Text('Access restricted to authorized administrators only.',
                  style: GoogleFonts.inter(color: kTextMuted, fontSize: 13)),
              const SizedBox(height: 36),
              _buildFormFields(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared form fields ───────────────────────────────────────────────────
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        Text('Email Address',
            style: GoogleFonts.inter(
                color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.email_outlined, color: kTextMuted, size: 18),
            hintText: 'admin@edumarket.in',
          ),
        ),
        const SizedBox(height: 20),

        // Password
        Text('Password',
            style: GoogleFonts.inter(
                color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: kTextMuted, size: 18),
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: kTextMuted, size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),

        // Error message
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kError.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: kError, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: GoogleFonts.inter(color: kError, fontSize: 12)),
              ),
            ]),
          ).animate().shakeX(),
        ],

        const SizedBox(height: 28),

        // Login button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Sign In to Admin Console',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),

        const SizedBox(height: 28),
        Row(children: [
          const Expanded(child: Divider(color: kBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Demo credentials',
                style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
          ),
          const Expanded(child: Divider(color: kBorder)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: admin@edumarket.in',
                  style: GoogleFonts.jetBrainsMono(color: kTextMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Password: admin123',
                  style: GoogleFonts.jetBrainsMono(color: kTextMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
