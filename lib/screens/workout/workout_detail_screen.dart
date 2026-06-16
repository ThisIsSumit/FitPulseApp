import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  workout.image.isNotEmpty
                      ? Image.network(workout.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.bgElevated))
                      : Container(color: AppColors.bgElevated),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.bgDark],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(workout.name,
                            style: AppTextStyles.displayMedium),
                      ),
                      DifficultyBadge(level: workout.difficulty),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Meta chips
                  Row(
                    children: [
                      _MetaChip(
                          icon: Icons.category_outlined,
                          label: workout.category),
                      const SizedBox(width: 10),
                      _MetaChip(
                          icon: Icons.timer_outlined,
                          label: '${workout.duration} min'),
                      const SizedBox(width: 10),
                      _MetaChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '${workout.calories} kcal'),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Exercises header
                  Text('${workout.exercises.length} Exercises',
                      style: AppTextStyles.headlineMedium)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 14),

                  // Exercise list
                  ...workout.exercises.asMap().entries.map((e) =>
                      _ExerciseTile(
                          index: e.key, exercise: e.value)),

                  const SizedBox(height: 32),

                  // Start button
                  GradientButton(
                    label: 'Start Workout',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => context.push(
                        '/workouts/${workout.id}/active',
                        extra: workout),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                    label: const Text('Save to My Plans'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final int index;
  final Exercise exercise;

  const _ExerciseTile({required this.index, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: AppColors.bgDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                    '${exercise.sets} sets × ${exercise.reps} ${exercise.reps > 30 ? 'sec' : 'reps'}',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          if (exercise.rest > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${exercise.rest}s rest',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60 + 200).ms, duration: 350.ms)
        .slideX(begin: 0.15, end: 0);
  }
}
