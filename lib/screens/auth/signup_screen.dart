import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _accepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_form.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms to continue.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create\nAccount 🚀',
                  style: AppTextStyles.displayLarge.copyWith(height: 1.1))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),
              Text('Start your transformation today',
                  style: AppTextStyles.bodyMedium)
                  .animate()
                  .fadeIn(delay: 100.ms),

              const SizedBox(height: 36),

              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'John Doe',
                prefix: const Icon(Icons.person_outline,
                    color: AppColors.textMuted, size: 20),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 14),

              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefix: const Icon(Icons.mail_outline,
                    color: AppColors.textMuted, size: 20),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 14),

              AppTextField(
                controller: _passCtrl,
                label: 'Password',
                obscure: !_showPass,
                prefix: const Icon(Icons.lock_outline,
                    color: AppColors.textMuted, size: 20),
                suffix: IconButton(
                  icon: Icon(
                      _showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted, size: 20),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 14),

              AppTextField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                obscure: true,
                prefix: const Icon(Icons.lock_outline,
                    color: AppColors.textMuted, size: 20),
                validator: (v) {
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),

              // Terms
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: AppColors.primary,
                    checkColor: AppColors.bgDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          TextSpan(text: ' and '),
                          TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),

              if (auth.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Text(auth.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ).animate().shake(duration: 300.ms),

              const SizedBox(height: 24),

              GradientButton(
                label: 'Create Account',
                onTap: _signup,
                isLoading: auth.loading,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
