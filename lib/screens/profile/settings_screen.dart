import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _workoutReminders = true;
  bool _communityUpdates = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _SectionLabel(label: 'Account'),
        _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => context.push('/profile')),
        _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () => context.push('/forgot-password')),
        _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Settings', onTap: () {}),

        const SizedBox(height: 20),
        _SectionLabel(label: 'Notifications'),
        _ToggleTile(icon: Icons.notifications_outlined, label: 'Push Notifications',
            value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
        _ToggleTile(icon: Icons.fitness_center_outlined, label: 'Workout Reminders',
            value: _workoutReminders, onChanged: (v) => setState(() => _workoutReminders = v)),
        _ToggleTile(icon: Icons.group_outlined, label: 'Community Updates',
            value: _communityUpdates, onChanged: (v) => setState(() => _communityUpdates = v)),

        const SizedBox(height: 20),
        _SectionLabel(label: 'Preferences'),
        _SettingsTile(icon: Icons.language_outlined, label: 'Language',
            trailing: const Text('English', style: TextStyle(color: AppColors.textMuted)), onTap: () {}),
        _SettingsTile(icon: Icons.straighten_outlined, label: 'Units',
            trailing: const Text('Metric', style: TextStyle(color: AppColors.textMuted)), onTap: () {}),

        const SizedBox(height: 20),
        _SectionLabel(label: 'Support'),
        _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & FAQ', onTap: () {}),
        _SettingsTile(icon: Icons.star_outline_rounded, label: 'Rate the App', onTap: () {}),
        _SettingsTile(icon: Icons.info_outline_rounded, label: 'About',
            trailing: const Text('v1.0.0', style: TextStyle(color: AppColors.textMuted)), onTap: () {}),

        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Are you sure you want to sign out?',
                  style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out', style: TextStyle(color: AppColors.error))),
              ],
            ));
            if (confirmed == true) {
              await auth.signOut();
              if (context.mounted) context.go('/login');
            }
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error), minimumSize: const Size(double.infinity, 52)),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontSize: 13)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label.toUpperCase(),
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String label; final Widget? trailing; final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface)),
    child: ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon; final String label; final bool value; final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface)),
    child: ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
