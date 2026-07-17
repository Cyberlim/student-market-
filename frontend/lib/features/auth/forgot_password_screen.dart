import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      // Simulate API call
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSent = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  borderRadius: 30,
                  opacity: 0.07,
                  blur: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _isSent
                        ? Column(
                            key: const ValueKey('success_state'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.mark_email_read_rounded,
                                size: 64,
                                color: AppColors.success,
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 24),
                              Text(
                                'Check Your Email',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "We have sent password recovery instructions to ${_emailController.text}.",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 32),
                              GradientButton(
                                text: 'Back to Sign In',
                                onPressed: () => context.go('/auth/login'),
                              ),
                            ],
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              key: const ValueKey('form_state'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 24),
                                Text(
                                  'Forgot Password',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Enter your registered email address and we'll send you a link to reset your password.",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                GradientButton(
                                  text: 'Send Reset Link',
                                  isLoading: _isLoading,
                                  onPressed: _handleReset,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
