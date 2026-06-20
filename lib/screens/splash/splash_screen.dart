import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  String _status = 'Starting up...';

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bootstrap();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  /// Runs real initialization work in parallel while the splash animates,
  /// then navigates to the correct destination once everything is ready.
  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();

    // Kick off independent async tasks concurrently — not sequentially —
    // so total wait time is the SLOWEST task, not the sum of all of them.
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    setState(() => _status = 'Checking your session...');
    final sessionFuture = _waitForAuthResolved(authProvider);

    setState(() => _status = 'Loading preferences...');
    final settingsFuture = _waitForSettingsLoaded(settingsProvider);

    setState(() => _status = 'Warming up notifications...');
    final notificationsFuture = NotificationService.init().catchError((_) {
      // Don't block app startup if notification init has an issue
    });

    // Wait for all real work to finish
    await Future.wait([sessionFuture, settingsFuture, notificationsFuture]);

    setState(() => _status = 'Almost there...');

    // Enforce a minimum splash duration so it doesn't flash for 80ms on
    // fast connections — gives the animation room to actually play and
    // feels intentional rather than glitchy.
    const minDuration = Duration(milliseconds: 1600);
    final elapsed = stopwatch.elapsed;
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    // Route to the correct destination based on real auth state
    if (authProvider.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  /// AuthProvider resolves its session asynchronously via Supabase's
  /// onAuthStateChange stream — this waits for the first emission (or a
  /// short timeout) so we don't navigate before we actually know if the
  /// user is logged in.
  Future<void> _waitForAuthResolved(AuthProvider auth) async {
    // If a session already exists synchronously, no need to wait.
    if (auth.isLoggedIn) return;

    // Otherwise give the stream a brief window to resolve (handles the
    // case of a persisted Supabase session being restored on cold start).
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _waitForSettingsLoaded(SettingsProvider settings) async {
    if (settings.loaded) return;
    // Poll briefly — SettingsProvider loads from SharedPreferences in its
    // constructor; this just ensures we don't race ahead of it.
    var attempts = 0;
    while (!settings.loaded && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Stack(
          children: [
            // Ambient animated gradient blobs — same visual language as onboarding
            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                  begin: 0.25,
                  end: 0.5,
                  duration: 2200.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.purpleGradient,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                  begin: 0.2,
                  end: 0.45,
                  duration: 2600.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned.fill(
              child: Container(color: AppColors.bgDark.withOpacity(0.88)),
            ),

            // Center content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo with pulsing glow ring
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (context, child) {
                      final glow = 0.3 + (_glowCtrl.value * 0.4);
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(glow * 0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.fitness_center_rounded,
                            color: AppColors.bgDark, size: 64),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1),
                      )
                      .fade(duration: 400.ms),

                  const SizedBox(height: 32),

                  // App name
                  const Text(
                    'FitPulse',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  Text(
                    'Train. Track. Transform.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                  const Spacer(flex: 2),

                  // Loading indicator + live status text
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.9)),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _status,
                      key: ValueKey(_status),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
