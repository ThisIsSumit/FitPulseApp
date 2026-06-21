import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

/// Read-only profile view for OTHER users — shows their stats, follow button,
/// and is reached by tapping any name/avatar in the Community feed.
class PublicProfileScreen extends StatefulWidget {
  final String uid;
  const PublicProfileScreen({super.key, required this.uid});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  AppUser? _user;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    SB.publicProfileStream(widget.uid).listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() => _user = AppUser.fromMap(data));
      }
    }, onError: (e) {
      print('⚠️ Public profile stream error: $e');
    });
  }

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    try {
      await SB.toggleFollow(widget.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update follow status: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = SB.uid ?? '';
    final isMe = widget.uid == myUid;
    final isFollowing = _user?.followers.contains(myUid) ?? false;

    // Redirect current user to their own profile screen
    if (isMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile');
      });

      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: Text(_user?.name ?? 'Profile')),
      body: _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        photoUrl: _user!.photoUrl,
                        name: _user!.name,
                        radius: 48,
                        hasStory: _user!.streak > 0,
                      )
                          .animate()
                          .scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(_user!.name, style: AppTextStyles.displayMedium)
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 4),
                      Text(
                        _user!.bio.isNotEmpty ? _user!.bio : 'No bio yet',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text('Level ${_user!.level}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatColumn(
                              count: _user!.followers.length,
                              label: 'Followers'),
                          Container(
                              width: 1,
                              height: 30,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              color: AppColors.bgSurface),
                          _StatColumn(
                              count: _user!.following.length,
                              label: 'Following'),
                          Container(
                              width: 1,
                              height: 30,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              color: AppColors.bgSurface),
                          _StatColumn(
                              count: _user!.totalWorkouts, label: 'Workouts'),
                        ],
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 20),
                      if (!isMe)
                        SizedBox(
                          width: 200,
                          child: isFollowing
                              ? OutlinedButton.icon(
                                  onPressed:
                                      _followLoading ? null : _toggleFollow,
                                  icon: _followLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.check_rounded,
                                          size: 18),
                                  label: const Text('Following'),
                                )
                              : GradientButton(
                                  label:
                                      _followLoading ? 'Loading...' : 'Follow',
                                  isLoading: _followLoading,
                                  height: 48,
                                  onTap: _toggleFollow,
                                ),
                        ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Stats'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                        label: 'Total Workouts',
                        value: '${_user!.totalWorkouts}',
                        unit: '',
                        gradient: AppColors.primaryGradient,
                        icon: Icons.fitness_center_rounded),
                    StatCard(
                        label: 'Calories Burned',
                        value: '${_user!.totalCaloriesBurned}',
                        unit: 'kcal',
                        gradient: AppColors.orangeGradient,
                        icon: Icons.local_fire_department_rounded),
                    StatCard(
                        label: 'Streak',
                        value: '${_user!.streak}',
                        unit: 'days',
                        gradient: AppColors.purpleGradient,
                        icon: Icons.bolt_rounded),
                    StatCard(
                        label: 'XP',
                        value: '${_user!.xp}',
                        unit: 'points',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00B0FF), Color(0xFF00E5A0)]),
                        icon: Icons.star_rounded),
                  ],
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final int count;
  final String label;
  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$count',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      );
}
