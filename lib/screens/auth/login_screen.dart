import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: AppColors.bgDark, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Text('FitPulse',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 52),

                Text('Welcome\nBack 👋',
                    style: AppTextStyles.displayLarge.copyWith(height: 1.1))
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text("Sign in to continue your fitness journey",
                    style: AppTextStyles.bodyMedium)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // Email
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
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Password
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
                        color: AppColors.textMuted,
                        size: 20),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot Password?',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),

                // Error
                if (auth.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 300.ms),

                const SizedBox(height: 8),

                GradientButton(
                  label: 'Sign In',
                  onTap: _login,
                  isLoading: auth.loading,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.bgSurface)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style: AppTextStyles.bodyMedium),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.bgSurface)),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: const Text('Sign Up',
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
      ),
    );
  }
}
