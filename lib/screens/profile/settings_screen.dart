import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _SectionLabel(label: 'Account'),
        _SettingsTile(
          icon: Icons.person_outline_rounded,
          label: 'Edit Profile',
          onTap: () => context.push('/profile'),
        ),
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () => _showChangePasswordSheet(context),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Settings',
          onTap: () => _showPrivacyInfo(context),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Notifications'),
        _ToggleTile(
          icon: Icons.notifications_outlined,
          label: 'Push Notifications',
          value: settings.pushNotifications,
          onChanged: (v) async {
            final ok = await settings.setPushNotifications(v);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Notification permission denied. Enable it in system settings.'),
                backgroundColor: AppColors.warning,
              ));
            }
          },
        ),
        _ToggleTile(
          icon: Icons.fitness_center_outlined,
          label: 'Workout Reminders',
          value: settings.workoutReminders,
          onChanged: settings.pushNotifications
              ? (v) => settings.setWorkoutReminders(v)
              : null, // disabled if master switch is off
        ),
        if (settings.workoutReminders && settings.pushNotifications)
          _SettingsTile(
            icon: Icons.schedule_outlined,
            label: 'Reminder Time',
            trailing: Text(settings.reminderTime.format(context),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: settings.reminderTime,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      surface: AppColors.bgCard,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) await settings.setReminderTime(picked);
            },
          ),
        _ToggleTile(
          icon: Icons.group_outlined,
          label: 'Community Updates',
          value: settings.communityUpdates,
          onChanged: settings.pushNotifications
              ? (v) => settings.setCommunityUpdates(v)
              : null,
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Preferences'),
        _SettingsTile(
          icon: Icons.language_outlined,
          label: 'Language',
          trailing: Text(settings.language,
              style: const TextStyle(color: AppColors.textMuted)),
          onTap: () => _showLanguagePicker(context, settings),
        ),
        _SettingsTile(
          icon: Icons.straighten_outlined,
          label: 'Units',
          trailing: Text(settings.units,
              style: const TextStyle(color: AppColors.textMuted)),
          onTap: () => _showUnitsPicker(context, settings),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Support'),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & FAQ',
          onTap: () => _showHelpSheet(context),
        ),
        _SettingsTile(
          icon: Icons.star_outline_rounded,
          label: 'Rate the App',
          onTap: () => _rateApp(context),
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'About',
          trailing: const Text('v1.0.0',
              style: TextStyle(color: AppColors.textMuted)),
          onTap: () => _showAboutDialog(context),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context, auth),
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label:
              const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 52)),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _confirmDeleteAccount(context, auth),
          child: const Text('Delete Account',
              style: TextStyle(color: AppColors.error, fontSize: 13)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Change Password ──────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Password',
                    style: AppTextStyles.headlineLarge),
                const SizedBox(height: 20),
                AppTextField(
                    controller: newPassCtrl,
                    label: 'New Password',
                    obscure: true),
                const SizedBox(height: 14),
                AppTextField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: true),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Update Password',
                  isLoading: loading,
                  onTap: () async {
                    if (newPassCtrl.text.length < 6) {
                      setState(() =>
                          error = 'Password must be at least 6 characters');
                      return;
                    }
                    if (newPassCtrl.text != confirmCtrl.text) {
                      setState(() => error = 'Passwords do not match');
                      return;
                    }
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    try {
                      await SB.auth.updateUser(
                          UserAttributes(password: newPassCtrl.text));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Password updated successfully'),
                          backgroundColor: AppColors.success,
                        ));
                      }
                    } catch (e) {
                      setState(() {
                        loading = false;
                        error = 'Failed to update password';
                      });
                    }
                  },
                ),
              ]),
        ),
      ),
    );
  }

  // ── Privacy info ─────────────────────────────────────────────
  void _showPrivacyInfo(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Privacy',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                'Your workout data, nutrition logs, and posts are stored securely in your Supabase project. '
                'Profile info (name, photo, bio) is visible to other users in the Community tab. '
                'Workout and nutrition logs are private and only visible to you.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'))
              ],
            ));
  }

  // ── Language picker ──────────────────────────────────────────
  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    final languages = ['English', 'Hindi', 'Spanish', 'French'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 16),
              ...languages.map((lang) => RadioListTile<String>(
                    value: lang,
                    groupValue: settings.language,
                    activeColor: AppColors.primary,
                    title: Text(lang,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    onChanged: (v) {
                      if (v != null) settings.setLanguage(v);
                      Navigator.pop(context);
                    },
                  )),
            ]),
      ),
    );
  }

  // ── Units picker ─────────────────────────────────────────────
  void _showUnitsPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Units', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 16),
              RadioListTile<String>(
                value: 'Metric',
                groupValue: settings.units,
                activeColor: AppColors.primary,
                title: const Text('Metric (kg, km)',
                    style: TextStyle(color: AppColors.textPrimary)),
                onChanged: (v) {
                  if (v != null) settings.setUnits(v);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                value: 'Imperial',
                groupValue: settings.units,
                activeColor: AppColors.primary,
                title: const Text('Imperial (lb, mi)',
                    style: TextStyle(color: AppColors.textPrimary)),
                onChanged: (v) {
                  if (v != null) settings.setUnits(v);
                  Navigator.pop(context);
                },
              ),
            ]),
      ),
    );
  }

  // ── Help & FAQ ───────────────────────────────────────────────
  void _showHelpSheet(BuildContext context) {
    final faqs = [
      (
        'How do I log a workout?',
        'Go to Workouts tab, pick a workout, tap Start, and follow the on-screen sets and rest timers.'
      ),
      (
        'How is my streak calculated?',
        'Your streak increases each consecutive day you complete at least one workout.'
      ),
      (
        'Can I edit a logged meal?',
        'Currently meals can only be added, not edited. Delete support is coming soon.'
      ),
      (
        'Is my data backed up?',
        'Yes — everything is stored in your Supabase project database and persists across devices when you sign in.'
      ),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Help & FAQ', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 16),
              ...faqs.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$1,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(f.$2, style: AppTextStyles.bodyMedium),
                        ]),
                  )),
            ]),
      ),
    );
  }

  // ── Rate App ─────────────────────────────────────────────────
  Future<void> _rateApp(BuildContext context) async {
    // Replace with your real Play Store / App Store URL once published
    const url = 'https://play.google.com/store/apps';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open store page')),
      );
    }
  }

  // ── About ────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FitPulse',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.fitness_center, color: AppColors.bgDark),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
              'Your all-in-one fitness companion — workouts, nutrition, and community.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  // ── Sign out ─────────────────────────────────────────────────
  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Are you sure you want to sign out?',
                  style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out',
                        style: TextStyle(color: AppColors.error))),
              ],
            ));
    if (confirmed == true) {
      await auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  // ── Delete account ──────────────────────────────────────────
  Future<void> _confirmDeleteAccount(
      BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Delete Account',
                  style: TextStyle(color: AppColors.error)),
              content: const Text(
                'This permanently deletes your profile, workout history, nutrition logs, and posts. This cannot be undone.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete Forever',
                        style: TextStyle(color: AppColors.error))),
              ],
            ));
    if (confirmed != true) return;

    try {
      final uid = SB.uid;
      if (uid != null) {
        // Deletes the auth user via RPC (requires the SQL function below)
        await SB.client.rpc('delete_own_account');
      }
      await auth.signOut();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgSurface)),
        child: ListTile(
          leading: Icon(icon, color: AppColors.textSecondary, size: 22),
          title: Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          trailing: trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bgSurface),
        ),
        child: ListTile(
          leading: Icon(icon,
              color: onChanged == null
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              size: 22),
          title: Text(label,
              style: TextStyle(
                  color: onChanged == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
          trailing: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}
