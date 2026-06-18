import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final health = context.watch<HealthProvider>();
    

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          '${_greeting()}, ${user?.name.split(' ').first ?? 'Athlete'}! 👋',
                          style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: AppTextStyles.bodyMedium),
                    ])),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: UserAvatar(
                      photoUrl: user?.photoUrl,
                      name: user?.name ?? '',
                      radius: 24),
                ),
              ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
            )),

            // ── Streak + XP banner ───────────────────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StreakBanner(user: user),
            )),

            // ── Today's calorie goal (REAL data) ────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SectionHeader(
                title: "Today's Goal",
                action: 'Set Goal',
                onAction: () => _showGoalSheet(context, health),
              ),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _TodayGoalCard(health: health),
            )),

            // ── Step counter (REAL pedometer) ────────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const SectionHeader(title: 'Steps Today'),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _StepCard(health: health),
            )),

            // ── Stats row (REAL from profile) ────────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const SectionHeader(title: 'Your Stats'),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _StatsRow(user: user, health: health),
            )),

            // ── Featured workouts ────────────────────────────
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

            // ── Challenges ───────────────────────────────────
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SectionHeader(
                  title: 'Active Challenges',
                  action: 'See All',
                  onAction: () => context.go('/community')),
            )),
            SliverToBoxAdapter(
                child: SizedBox(height: 130, child: _ChallengesList())),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

  void _showGoalSheet(BuildContext context, HealthProvider health) {
    final calCtrl = TextEditingController(text: health.calorieGoal.toString());
    final stepCtrl = TextEditingController(text: health.stepGoal.toString());
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
              const Text('Set Daily Goals', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 20),
              AppTextField(
                  controller: calCtrl,
                  label: 'Calorie Goal (kcal)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              AppTextField(
                  controller: stepCtrl,
                  label: 'Step Goal',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              GradientButton(
                  label: 'Save Goals',
                  onTap: () async {
                    final cal = int.tryParse(calCtrl.text) ?? 2500;
                    final step = int.tryParse(stepCtrl.text) ?? 10000;
                    await health.setCalorieGoal(cal);
                    await health.setStepGoal(step);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
            ]),
      ),
    );
  }
}

// ── Streak Banner ────────────────────────────────────────────
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
      child: Row(children: [
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
      ]),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ── Today Goal Card (REAL nutrition data) ─────────────────────
class _TodayGoalCard extends StatelessWidget {
  final HealthProvider health;
  const _TodayGoalCard({required this.health});

  @override
  Widget build(BuildContext context) {
    // Also watch NutritionProvider so card rebuilds when meals are logged
    final nutrition = context.watch<NutritionProvider>();
    final consumed = nutrition.todayCalories;
    final goal = health.calorieGoal;
    final burned = health.todayCaloriesBurned + health.stepCalories;
    final net = consumed - burned;
    final pct = (consumed / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(children: [
        Row(children: [
          CircularPercentIndicator(
            radius: 52,
            lineWidth: 8,
            percent: pct,
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(pct * 100).toInt()}%',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const Text('done',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ]),
            progressColor: pct >= 1.0 ? AppColors.warning : AppColors.primary,
            backgroundColor: AppColors.bgElevated,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 600,
          ),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Calorie Balance',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                _CalRow(
                    label: 'Consumed',
                    value: '$consumed kcal',
                    color: AppColors.info),
                const SizedBox(height: 4),
                _CalRow(
                    label: 'Burned',
                    value: '$burned kcal',
                    color: AppColors.error),
                const Divider(color: AppColors.bgSurface, height: 12),
                _CalRow(
                    label: 'Net',
                    value: '$net kcal',
                    color: net > goal ? AppColors.warning : AppColors.primary),
                const SizedBox(height: 4),
                _CalRow(
                    label: 'Remaining',
                    value: '${(goal - consumed).clamp(0, goal)} kcal',
                    color: AppColors.textSecondary),
              ])),
        ]),
        const SizedBox(height: 16),
        // Macro bars
        Row(children: [
          Expanded(
              child: _MacroBar(
                  label: 'Protein',
                  value: nutrition.todayProtein,
                  goal: 150,
                  color: AppColors.info,
                  unit: 'g')),
          const SizedBox(width: 10),
          Expanded(
              child: _MacroBar(
                  label: 'Carbs',
                  value: nutrition.todayCarbs,
                  goal: 250,
                  color: AppColors.warning,
                  unit: 'g')),
          const SizedBox(width: 10),
          Expanded(
              child: _MacroBar(
                  label: 'Fat',
                  value: nutrition.todayFat,
                  goal: 80,
                  color: AppColors.error,
                  unit: 'g')),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.go('/nutrition'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.bgDark, size: 18),
                  SizedBox(width: 6),
                  Text('Log a Meal',
                      style: TextStyle(
                          color: AppColors.bgDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
          ),
        ),
      ]),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _CalRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CalRow(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      );
}

class _MacroBar extends StatelessWidget {
  final String label, unit;
  final double value, goal;
  final Color color;
  const _MacroBar(
      {required this.label,
      required this.value,
      required this.goal,
      required this.color,
      required this.unit});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text('${value.toInt()}$unit',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / goal).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('/ ${goal.toInt()}$unit',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        ],
      );
}

// ── Step Card (REAL pedometer) ────────────────────────────────
class _StepCard extends StatelessWidget {
  final HealthProvider health;
  const _StepCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final steps = health.steps;
    final goal = health.stepGoal;
    final pct = health.stepProgress;
    final calBurned = health.stepCalories;
    final km = (steps * 0.000762).toStringAsFixed(2); // avg stride 76.2cm

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: health.stepAvailable
          ? Row(children: [
              // Ring
              CircularPercentIndicator(
                radius: 44,
                lineWidth: 7,
                percent: pct,
                center: Text('${(pct * 100).toInt()}%',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                progressColor: AppColors.secondary,
                backgroundColor: AppColors.bgElevated,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 600,
              ),
              const SizedBox(width: 18),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$steps',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 28)),
                      const SizedBox(width: 4),
                      Text('/ $goal steps',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _StepPill(
                          icon: Icons.local_fire_department_rounded,
                          label: '$calBurned kcal',
                          color: AppColors.error),
                      const SizedBox(width: 8),
                      _StepPill(
                          icon: Icons.straighten_rounded,
                          label: '$km km',
                          color: AppColors.info),
                    ]),
                  ])),
            ])
          : Row(children: [
              const Icon(Icons.directions_walk_rounded,
                  color: AppColors.textMuted, size: 32),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Step Counter Unavailable',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Grant activity permission to track steps.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => openAppSettings(),
                      child: const Text('Open Settings →',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ])),
            ]),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _StepPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StepPill(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AppUser? user;
  final HealthProvider health;
  const _StatsRow({this.user, required this.health});

  @override
  Widget build(BuildContext context) {
    // Today's burned = workout logs + step calories
    final todayBurned = health.todayCaloriesBurned + health.stepCalories;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(
            child: SizedBox(
                height: 130,
                child: StatCard(
                    label: 'Total Workouts',
                    value: '${user?.totalWorkouts ?? 0}',
                    unit: '',
                    gradient: AppColors.primaryGradient,
                    icon: Icons.fitness_center_rounded))),
        const SizedBox(width: 12),
        Expanded(
            child: SizedBox(
                height: 130,
                child: StatCard(
                    label: 'All-time Burned',
                    value: '${user?.totalCaloriesBurned ?? 0}',
                    unit: 'kcal',
                    gradient: AppColors.orangeGradient,
                    icon: Icons.local_fire_department_rounded))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: SizedBox(
                height: 130,
                child: StatCard(
                    label: 'Today Burned',
                    value: '$todayBurned',
                    unit: 'kcal',
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF9500)]),
                    icon: Icons.whatshot_rounded))),
        const SizedBox(width: 12),
        Expanded(
            child: SizedBox(
                height: 130,
                child: StatCard(
                    label: 'Streak',
                    value: '${user?.streak ?? 0}',
                    unit: 'days',
                    gradient: AppColors.purpleGradient,
                    icon: Icons.bolt_rounded))),
      ]),
    ])
        .animate()
        .fadeIn(delay: 250.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ── Featured Workouts ─────────────────────────────────────────
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
    if (_workouts!.isEmpty) {
      return const Center(
          child: Text('No workouts yet',
              style: TextStyle(color: AppColors.textMuted)));
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

// ── Challenges List ───────────────────────────────────────────
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
    if (_challenges!.isEmpty) {
      return const Center(
          child: Text('No challenges yet',
              style: TextStyle(color: AppColors.textMuted)));
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
    final uid = SB.uid ?? '';
    final isJoined = challenge.isJoined(uid);

    return GestureDetector(
      onTap: () => context.go('/community'),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isJoined
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.bgSurface)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(challenge.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(challenge.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            if (isJoined)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('✓ In',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 8),
          Text('${challenge.daysLeft} days left',
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${challenge.participants.length} participants joined',
              style: AppTextStyles.caption),
        ]),
      ),
    );
  }
}
