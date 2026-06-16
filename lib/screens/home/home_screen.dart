import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${_greeting()}, ${user?.name.split(' ').first ?? 'Athlete'}! 👋',
                              style: AppTextStyles.headlineLarge),
                          const SizedBox(height: 4),
                          Text(
                              DateFormat('EEEE, MMMM d').format(DateTime.now()),
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: UserAvatar(
                          photoUrl: user?.photoUrl,
                          name: user?.name ?? '',
                          radius: 24),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),
              ),
            ),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StreakBanner(user: user),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const SectionHeader(title: "Today's Goal"),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _TodayGoalCard(),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const SectionHeader(title: 'Your Stats'),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _StatsRow(user: user),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SectionHeader(
                  title: 'Featured Workouts',
                  action: 'See All',
                  onAction: () => context.go('/workouts')),
            )),
            SliverToBoxAdapter(
                child: SizedBox(height: 200, child: _FeaturedWorkoutsList())),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SectionHeader(
                  title: 'Challenges',
                  action: 'See All',
                  onAction: () => context.go('/community')),
            )),
            SliverToBoxAdapter(
                child: SizedBox(height: 130, child: _ChallengesList())),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _StreakBanner extends StatelessWidget {
  final AppUser? user;
  const _StreakBanner({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('${user?.streak ?? 0} Day Streak',
                  style: const TextStyle(
                      color: AppColors.bgDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            Text("Keep it going! You're on fire.",
                style: TextStyle(
                    color: AppColors.bgDark.withOpacity(0.7), fontSize: 13)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Level ${user?.level ?? 1}',
                style: const TextStyle(
                    color: AppColors.bgDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 6),
            SizedBox(
              width: 90,
              child: LinearProgressIndicator(
                value: user?.xpProgress ?? 0,
                backgroundColor: AppColors.bgDark.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.bgDark),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text('${user?.xp ?? 0} / ${user?.xpToNextLevel ?? 500} XP',
                style: TextStyle(
                    color: AppColors.bgDark.withOpacity(0.7), fontSize: 11)),
          ]),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _TodayGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 48,
          lineWidth: 7,
          percent: 0.65,
          center: const Text('65%',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          progressColor: AppColors.primary,
          backgroundColor: AppColors.bgElevated,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(width: 20),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Calorie Goal',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('1,625 / 2,500 kcal',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 12),
          Row(children: [
            _MacroPill(label: 'P', value: '112g', color: AppColors.info),
            const SizedBox(width: 6),
            _MacroPill(label: 'C', value: '205g', color: AppColors.warning),
            const SizedBox(width: 6),
            _MacroPill(label: 'F', value: '68g', color: AppColors.error),
          ]),
        ])),
      ]),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _MacroPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroPill(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$value $label',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _StatsRow extends StatelessWidget {
  final AppUser? user;
  const _StatsRow({this.user});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: SizedBox(
              height: 110,
              child: StatCard(
                  label: 'Workouts',
                  value: '${user?.totalWorkouts ?? 0}',
                  unit: '',
                  gradient: AppColors.primaryGradient,
                  icon: Icons.fitness_center_rounded))),
      const SizedBox(width: 12),
      Expanded(
          child: SizedBox(
              height: 110,
              child: StatCard(
                  label: 'Burned',
                  value: '${user?.totalCaloriesBurned ?? 0}',
                  unit: 'kcal',
                  gradient: AppColors.orangeGradient,
                  icon: Icons.local_fire_department_rounded))),
      const SizedBox(width: 12),
      Expanded(
          child: SizedBox(
              height: 110,
              child: StatCard(
                  label: 'Streak',
                  value: '${user?.streak ?? 0}',
                  unit: 'days',
                  gradient: AppColors.purpleGradient,
                  icon: Icons.bolt_rounded))),
    ])
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _FeaturedWorkoutsList extends StatefulWidget {
  @override
  State<_FeaturedWorkoutsList> createState() => _FeaturedWorkoutsListState();
}

class _FeaturedWorkoutsListState extends State<_FeaturedWorkoutsList> {
  List<Workout>? _workouts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SB.fetchWorkouts();
    if (mounted)
      setState(() => _workouts = data.map(Workout.fromMap).take(6).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_workouts == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) =>
            const ShimmerBox(width: 180, height: 180, borderRadius: 20),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      scrollDirection: Axis.horizontal,
      itemCount: _workouts!.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, i) => _WorkoutCard(workout: _workouts![i], index: i),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final int index;
  const _WorkoutCard({required this.workout, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workouts/${workout.id}', extra: workout),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: AppColors.bgCard),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
              child: workout.image.isNotEmpty
                  ? Image.network(workout.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.bgElevated))
                  : Container(color: AppColors.bgElevated)),
          Positioned.fill(
              child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87])))),
          Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DifficultyBadge(level: workout.difficulty),
                  const SizedBox(height: 6),
                  Text(workout.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                      maxLines: 2),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text('${workout.duration}m',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text('${workout.calories} kcal',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              )),
        ]),
      )
          .animate()
          .fadeIn(delay: (index * 80).ms, duration: 400.ms)
          .slideX(begin: 0.2, end: 0),
    );
  }
}

class _ChallengesList extends StatefulWidget {
  @override
  State<_ChallengesList> createState() => _ChallengesListState();
}

class _ChallengesListState extends State<_ChallengesList> {
  List<Challenge>? _challenges;

  @override
  void initState() {
    super.initState();
    SB.challengesStream().listen((data) {
      if (mounted)
        setState(
            () => _challenges = data.map(Challenge.fromMap).take(5).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) =>
            const ShimmerBox(width: 230, height: 120, borderRadius: 16),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      scrollDirection: Axis.horizontal,
      itemCount: _challenges!.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, i) => _ChallengeChip(challenge: _challenges![i]),
    );
  }
}

class _ChallengeChip extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeChip({required this.challenge});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bgSurface)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(challenge.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(challenge.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text('${challenge.daysLeft} days left',
            style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('${challenge.participants.length} participants',
            style: AppTextStyles.caption),
      ]),
    );
  }
}
