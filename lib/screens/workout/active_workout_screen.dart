import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  const ActiveWorkoutScreen({super.key, required this.workout});
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with TickerProviderStateMixin {
  int _currentIndex = 0, _currentSet = 1, _elapsedSeconds = 0, _restCountdown = 0;
  bool _resting = false;
  Timer? _workoutTimer, _restTimer;
  late List<Exercise> _exercises;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _exercises = widget.workout.exercises
        .map((e) => Exercise(name: e.name, sets: e.sets, reps: e.reps, rest: e.rest))
        .toList();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800), lowerBound: 0.95, upperBound: 1.05)
      ..repeat(reverse: true);
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsedSeconds++));
  }

  @override
  void dispose() { _workoutTimer?.cancel(); _restTimer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _startRest(int s) {
    setState(() { _resting = true; _restCountdown = s; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _restCountdown--);
      if (_restCountdown <= 0) { t.cancel(); setState(() => _resting = false); }
    });
  }

  void _completeSet() {
    final ex = _exercises[_currentIndex];
    if (_currentSet < ex.sets) {
      final rest = ex.rest;
      setState(() => _currentSet++);
      if (rest > 0) _startRest(rest);
    } else {
      _exercises[_currentIndex].completed = true;
      if (_currentIndex < _exercises.length - 1) {
        final rest = _exercises[_currentIndex].rest;
        setState(() { _currentIndex++; _currentSet = 1; });
        if (rest > 0) _startRest(rest);
      } else {
        _finishWorkout();
      }
    }
  }

  Future<void> _finishWorkout() async {
    _workoutTimer?.cancel(); _restTimer?.cancel();
    final auth = context.read<AuthProvider>();
    final uid = SB.uid;
    if (uid != null) {
      await SB.logWorkout({
        'workout_id': widget.workout.id,
        'workout_name': widget.workout.name,
        'duration': _elapsedSeconds ~/ 60,
        'calories': widget.workout.calories,
        'exercises_count': widget.workout.exercises.length,
      });
      await SB.incrementProfileStats(id: uid, workouts: 1, calories: widget.workout.calories, xp: 100);
      auth.refreshUser();
    }
    if (mounted) _showCompletion();
  }

  void _showCompletion() {
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.bgCard,
      isScrollControlled: true, isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 90, height: 90,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 44))))
              .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('Workout Complete!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Amazing job! You crushed it today.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: _StatPill(label: 'Duration', value: '${_elapsedSeconds ~/ 60}m', icon: Icons.timer_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _StatPill(label: 'Calories', value: '${widget.workout.calories}', icon: Icons.local_fire_department_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _StatPill(label: 'XP', value: '+100', icon: Icons.bolt_rounded)),
          ]),
          const SizedBox(height: 28),
          GradientButton(label: 'Back to Home', onTap: () => context.go('/home')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () { Navigator.pop(context); context.push('/community/create-post'); },
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Share Your Achievement'),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  String get _elapsed {
    final m = _elapsedSeconds ~/ 60, s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final done = _exercises.where((e) => e.completed).length;
    final partial = (_currentSet - 1) / _exercises[_currentIndex].sets;
    return (done + partial) / _exercises.length;
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exercises[_currentIndex];
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.workout.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => _confirmQuit(context)),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16),
          child: Text(_elapsed, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18, fontFamily: 'monospace'))))],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Exercise ${_currentIndex + 1} of ${_exercises.length}', style: AppTextStyles.bodyMedium),
            Text('${(_progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
            value: _progress, minHeight: 6,
            backgroundColor: AppColors.bgSurface,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          )),
        ])),
        const SizedBox(height: 24),
        if (_resting)
          Expanded(child: _RestScreen(countdown: _restCountdown, onSkip: () { _restTimer?.cancel(); setState(() => _resting = false); }))
        else
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28)),
              child: Column(children: [
                ScaleTransition(scale: _pulseCtrl, child: Text(_emoji(ex.name), style: const TextStyle(fontSize: 72))),
                const SizedBox(height: 16),
                Text(ex.name, style: const TextStyle(color: AppColors.bgDark, fontSize: 26, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('${ex.reps} ${ex.reps > 30 ? 'seconds' : 'reps'}',
                    style: TextStyle(color: AppColors.bgDark.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w500)),
              ]),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(ex.sets, (i) =>
              AnimatedContainer(duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: i < _currentSet ? 32 : 28, height: i < _currentSet ? 32 : 28,
                decoration: BoxDecoration(
                  color: i < _currentSet - 1 ? AppColors.primary : i == _currentSet - 1 ? AppColors.primary.withOpacity(0.3) : AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: i == _currentSet - 1 ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
                child: Center(child: Text('${i + 1}', style: TextStyle(
                    color: i < _currentSet ? AppColors.bgDark : AppColors.textMuted,
                    fontWeight: FontWeight.w700, fontSize: 13))),
              ),
            )),
            const SizedBox(height: 8),
            Text('Set $_currentSet of ${ex.sets}', style: AppTextStyles.bodyMedium),
            const Spacer(),
            GradientButton(
              label: _currentSet == ex.sets && _currentIndex == _exercises.length - 1 ? 'Finish Workout 🏆' : 'Complete Set $_currentSet',
              onTap: _completeSet, height: 60,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () { if (_currentIndex < _exercises.length - 1) setState(() { _currentIndex++; _currentSet = 1; }); },
              child: const Text('Skip Exercise', style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 16),
            if (_currentIndex < _exercises.length - 1)
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.skip_next_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Text('Next: ', style: AppTextStyles.bodyMedium),
                  Text(_exercises[_currentIndex + 1].name,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(height: 20),
          ]))),
      ]),
    );
  }

  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('push')) return '💪';
    if (n.contains('squat')) return '🦵';
    if (n.contains('plank')) return '🏋️';
    if (n.contains('run') || n.contains('jump')) return '🏃';
    if (n.contains('curl') || n.contains('press')) return '💪';
    if (n.contains('yoga') || n.contains('pose')) return '🧘';
    if (n.contains('crunch') || n.contains('ab')) return '🔥';
    return '⚡';
  }

  void _confirmQuit(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Quit Workout?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Progress will not be saved.', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
        TextButton(onPressed: () { Navigator.pop(ctx); context.go('/workouts'); },
            child: const Text('Quit', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }
}

class _RestScreen extends StatelessWidget {
  final int countdown;
  final VoidCallback onSkip;
  const _RestScreen({required this.countdown, required this.onSkip});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('😮‍💨', style: TextStyle(fontSize: 60)),
    const SizedBox(height: 20),
    const Text('Rest Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 20, fontWeight: FontWeight.w600)),
    const SizedBox(height: 12),
    Text('$countdown', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: AppColors.primary, fontFamily: 'monospace'))
        .animate(key: ValueKey(countdown)).scale(duration: 200.ms, curve: Curves.easeOut),
    const SizedBox(height: 8),
    const Text('seconds', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
    const SizedBox(height: 40),
    OutlinedButton(onPressed: onSkip, child: const Text('Skip Rest')),
  ]));
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatPill({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}
