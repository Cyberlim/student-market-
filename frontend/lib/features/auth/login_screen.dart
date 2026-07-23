import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      // Simulate API loading for email/password and redirect to Home
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          context.go('/');
        }
      });
    }
  }

  Future<void> _showMockSignInDialog(String originalError) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Google Login Bypass',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Google Sign-In is not configured on this device (requires SHA-1 registration in developer console).',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  'Would you like to bypass this check and log in with a mock Google developer account connected to the backend?',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Use Mock Account',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitGoogleCredentialsToBackend(
                  token: 'mock_developer_google_token_1234',
                  email: 'mock.student@university.edu',
                  name: 'Mock Developer Student',
                  avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=120',
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitGoogleCredentialsToBackend({
    required String token,
    required String email,
    required String name,
    required String avatar,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      final String baseUrl = backendBaseUrl;

      final response = await dio.post(
        '$baseUrl/auth/google',
        data: {
          'token': token,
          'email': email,
          'name': name,
          'avatar': avatar,
        },
      );

      if (response.data['success'] == true) {
        final jwtToken = response.data['token'];
        final userData = response.data['user'];

        // Save session parameters locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken);
        await prefs.setString('user_id', userData['_id'] ?? '');
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_avatar', userData['avatar'] ?? '');
        await prefs.setString('user_role', userData['role'] ?? 'Student');
        await prefs.setString('user_college', userData['college'] ?? '');
        await prefs.setString('user_department', userData['department'] ?? '');
        await prefs.setString('user_phone', userData['phone'] ?? '');
        await prefs.setInt('user_coins', ((userData['coins'] ?? 100) as num).toInt());
        final isProfileComplete = userData['isProfileComplete'] == true;
        await prefs.setBool('profile_complete', isProfileComplete);

        // Register FCM token now that user is logged in
        NotificationService.instance.registerFcmToken();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome, ${userData['name']}! 🎉',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          // Redirect new users to complete their profile
          if (!isProfileComplete) {
            context.go('/auth/complete-profile');
          } else {
            context.go('/');
          }
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to authenticate');
      }
    } catch (e) {
      debugPrint('Backend Auth Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backend Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      await _submitGoogleCredentialsToBackend(
        token: idToken ?? accessToken ?? '',
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        avatar: googleUser.photoUrl ?? '',
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        await _showMockSignInDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Glow Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: isDark ? 0.20 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Squircle login card (Glassmorphic look)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Logo Icon
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. Title
                            Center(
                              child: Text(
                                'Welcome Back',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // 3. Subtitle
                            Center(
                              child: Text(
                                'Sign in to access your study library',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // 4. Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade500, size: 18),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 5. Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey.shade500, size: 18),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.grey.shade500,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            // 6. Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push('/auth/forgot-password'),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 7. Premium Sign In Button
                            SizedBox(
                              height: 48,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _handleLogin,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 8. Divider (or)
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or continue with',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 9. Premium Full Width Google Sign-In Button (Apple removed)
                            InkWell(
                              onTap: _isLoading ? null : _handleGoogleSignIn,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.png',
                                      height: 18,
                                      width: 18,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Sign in with Google',
                                      style: GoogleFonts.inter(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 10. Sign Up Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/auth/register'),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 11. Disclaimer Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'By signing in, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
