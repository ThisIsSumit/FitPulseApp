import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SB.resetPassword(_emailCtrl.text.trim());
      setState(() { _sent = true; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_sent) ...[
              const Text('🔑', style: TextStyle(fontSize: 52))
                  .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('Forgot\nPassword?', style: AppTextStyles.displayLarge.copyWith(height: 1.1))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text('Enter your email and we\'ll send you a reset link.',
                  style: AppTextStyles.bodyMedium).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefix: const Icon(Icons.mail_outline, color: AppColors.textMuted, size: 20),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Send Reset Link',
                onTap: _send,
                isLoading: _loading,
              ).animate().fadeIn(delay: 250.ms),
            ] else ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 72))
                        .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    Text('Email Sent!', style: AppTextStyles.displayMedium)
                        .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    Text(
                      'Check your inbox at\n${_emailCtrl.text}\nfor a password reset link.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 36),
                    GradientButton(
                      label: 'Back to Sign In',
                      onTap: () => context.go('/login'),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
