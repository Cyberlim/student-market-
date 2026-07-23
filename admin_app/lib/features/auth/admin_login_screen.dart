import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';
import '../../core/services/notification_service.dart';

// Only this Google account is allowed admin access
const _allowedEmail = 'kuldeepsengar5678@gmail.com';

final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '86243436179-7543sabtenl2muiabjlbudte6m4aee5t.apps.googleusercontent.com',
);

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Sign out first to always show account picker
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled
        setState(() { _loading = false; });
        return;
      }

      // Enforce allowed email
      if (account.email.toLowerCase() != _allowedEmail.toLowerCase()) {
        await _googleSignIn.signOut();
        setState(() {
          _error = 'Access denied. Only the authorised admin account can log in.';
          _loading = false;
        });
        return;
      }

      // Get the ID token to send to our backend
      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() { _error = 'Google sign-in failed. No token received.'; _loading = false; });
        return;
      }

      // Exchange Google ID token for our JWT via backend
      final response = await AdminApiService.request(
        'POST',
        '/api/auth/google',
        data: { 
          'idToken': idToken,
          'email': account.email,
          'name': account.displayName ?? 'Admin',
          'avatar': account.photoUrl ?? '',
        },
      );

      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        final user = response.data['user'] ?? {};
        // Ensure the backend assigned Admin role
        if (user['role'] != 'Admin') {
          setState(() {
            _error = 'Access denied. This account does not have Admin privileges.';
            _loading = false;
          });
          return;
        }

        final token = response.data['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          AdminNotificationService.instance.registerFcmToken();
        }

        if (mounted) context.go('/');
      } else {
        final msg = response?.data?['message'] ?? 'Login failed. Please try again.';
        setState(() { _error = msg; _loading = false; });
      }
    } catch (e) {
      setState(() {
        _error = 'Sign-in error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return isMobile ? _buildMobile() : _buildDesktop();
      }),
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
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
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                const SizedBox(height: 6),
                Text('Secure admin control panel. Authorised access only.',
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: _buildSignInCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
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
                      height: 1.2)),
              const SizedBox(height: 16),
              Text('Secure control panel for managing the\nEduMarket notes marketplace platform.',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.6)),
              const SizedBox(height: 48),
              ...['Notes moderation & approval queue',
                  'User account management & analytics',
                  'Platform revenue & fee configuration',
                  'Dispute resolution & content reports'].map((t) => Padding(
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
                    color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 26)),
            const SizedBox(height: 8),
            Text('Access restricted to authorised administrators only.',
                style: GoogleFonts.inter(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 36),
            _buildSignInCard(),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSignInCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign-In Button
        _GoogleSignInButton(loading: _loading, onTap: _signInWithGoogle),

        // Error
        if (_error != null) ...[
          const SizedBox(height: 20),
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
                child: Text(_error!, style: GoogleFonts.inter(color: kError, fontSize: 12)),
              ),
            ]),
          ).animate().shakeX(),
        ],

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline_rounded, color: kTextMuted, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Only the authorised admin Google account can access this panel.',
                style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Google Sign-In Button ────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: loading ? kSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: loading
            ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G logo using coloured squares
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF3C4043),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final r = size.width / 2;

    // Draw the G using arcs and rectangles
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    // Simple colored circle segments approximation
    canvas.drawArc(rect, -1.57, 3.14, false, bluePaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18);
    canvas.drawArc(rect, 1.57, 1.57, false, greenPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18);
    canvas.drawArc(rect, -3.14, 1.57, false, redPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18);
    canvas.drawArc(rect, 0, 1.57, false, yellowPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18);

    // Horizontal bar of the G
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - size.height * 0.09,
          r - size.width * 0.09, size.height * 0.18),
      bluePaint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
