import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _liveUser;
  List<WorkoutLog> _logs = [];

  @override
  void initState() {
    super.initState();
    final uid = SB.uid ?? '';
    // Live profile stream
    SB.profileStream(uid).listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() => _liveUser = AppUser.fromMap(data));
      }
    });
    // Workout logs stream
    SB.workoutLogsStream(uid).listen((data) {
      if (mounted) {
        setState(() => _logs = data.map(WorkoutLog.fromMap).toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _liveUser ?? context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          )
        ],
      ),
      body: ListView(children: [
        _ProfileHeader(user: user),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const SectionHeader(title: 'My Stats')),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _StatsGrid(user: user)),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const SectionHeader(title: 'Workout History (7 days)')),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _WorkoutHistoryChart(logs: _logs)),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: const SectionHeader(title: 'Recent Activity')),
        _RecentActivity(logs: _logs),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser? user;
  const _ProfileHeader({this.user});

  Future<void> _pickAndUpload(BuildContext context) async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final uid = SB.uid;
    if (uid == null) return;
    try {
      await SB.uploadAvatar(uid, File(file.path));
      context.read<AuthProvider>().refreshUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        GestureDetector(
          onTap: () => _pickAndUpload(context),
          child: Stack(children: [
            UserAvatar(
                photoUrl: user?.photoUrl,
                name: user?.name ?? '',
                radius: 48,
                hasStory: (user?.streak ?? 0) > 0),
            Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: AppColors.bgDark),
                )),
          ]),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 12),
        Text(user?.name ?? '', style: AppTextStyles.displayMedium)
            .animate()
            .fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(user?.bio.isNotEmpty == true ? user!.bio : 'No bio yet',
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 150.ms),
        const SizedBox(height: 16),

        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Level ${user?.level ?? 1}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(width: 10),
            Text('${user?.xp ?? 0} XP',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _FollowStat(count: user?.followers.length ?? 0, label: 'Followers'),
          Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.bgSurface),
          _FollowStat(count: user?.following.length ?? 0, label: 'Following'),
          Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.bgSurface),
          _FollowStat(count: user?.totalWorkouts ?? 0, label: 'Workouts'),
        ]).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _showEditProfile(context, user),
          style: OutlinedButton.styleFrom(minimumSize: const Size(180, 44)),
          child: const Text('Edit Profile'),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  void _showEditProfile(BuildContext context, AppUser? user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final bioCtrl = TextEditingController(text: user?.bio ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 20),
              AppTextField(controller: nameCtrl, label: 'Display Name'),
              const SizedBox(height: 14),
              AppTextField(controller: bioCtrl, label: 'Bio', maxLines: 3),
              const SizedBox(height: 20),
              GradientButton(
                  label: 'Save Changes',
                  onTap: () async {
                    final uid = SB.uid;
                    if (uid == null) return;
                    await SB.updateProfile(uid, {
                      'name': nameCtrl.text.trim(),
                      'bio': bioCtrl.text.trim()
                    });
                    context.read<AuthProvider>().refreshUser();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
            ]),
      ),
    );
  }
}

class _FollowStat extends StatelessWidget {
  final int count;
  final String label;
  const _FollowStat({required this.count, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
        AnimatedNumber(
            value: count,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ]);
}

class _StatsGrid extends StatelessWidget {
  final AppUser? user;
  const _StatsGrid({this.user});
  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          StatCard(
              label: 'Total Workouts',
              value: '${user?.totalWorkouts ?? 0}',
              unit: '',
              gradient: AppColors.primaryGradient,
              icon: Icons.fitness_center_rounded),
          StatCard(
              label: 'Calories Burned',
              value: '${user?.totalCaloriesBurned ?? 0}',
              unit: 'kcal',
              gradient: AppColors.orangeGradient,
              icon: Icons.local_fire_department_rounded),
          StatCard(
              label: 'Streak',
              value: '${user?.streak ?? 0}',
              unit: 'days',
              gradient: AppColors.purpleGradient,
              icon: Icons.bolt_rounded),
          StatCard(
              label: 'Total XP',
              value: '${user?.xp ?? 0}',
              unit: 'experience',
              gradient: const LinearGradient(
                  colors: [Color(0xFF00B0FF), Color(0xFF00E5A0)]),
              icon: Icons.star_rounded),
        ],
      ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
}

class _WorkoutHistoryChart extends StatelessWidget {
  final List<WorkoutLog> logs;
  const _WorkoutHistoryChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<int, int> dayCounts = {for (var i = 0; i < 7; i++) i: 0};

    for (final l in logs) {
      final logDate = DateTime(l.date.year, l.date.month, l.date.day);
      final diff = today.difference(logDate).inDays;
      if (diff >= 0 && diff < 7) {
        dayCounts[6 - diff] = (dayCounts[6 - diff] ?? 0) + 1;
      }
    }

    final dayLabels = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateFormat('E')
          .format(d)
          .substring(0, 1); // single-letter, matches your current style
    });

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 3,
        barGroups: List.generate(
            7,
            (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: (dayCounts[i] ?? 0).toDouble(),
                      gradient: AppColors.primaryGradient,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6))),
                ])),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(dayLabels[v.toInt() % 7],
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)))),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      )),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }
}

class _RecentActivity extends StatelessWidget {
  final List<WorkoutLog> logs;
  const _RecentActivity({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: EmptyState(
            emoji: '🏋️',
            title: 'No workouts yet',
            subtitle: 'Complete a workout to see it here'),
      );
    }

    return Column(
        children: logs.take(5).toList().asMap().entries.map((e) {
      final log = e.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bgSurface)),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(log.workoutName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text('${log.duration} min · ${log.calories} kcal',
                      style: AppTextStyles.caption),
                ])),
            Text(_fmtDate(log.date), style: AppTextStyles.caption),
          ]),
        ).animate().fadeIn(delay: (e.key * 60).ms, duration: 300.ms),
      );
    }).toList());
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${diff}d ago';
  }
}
