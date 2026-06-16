import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _selected = 'All';
  String _search = '';
  final _searchCtrl = TextEditingController();
  List<Workout>? _all;

  final _categories = ['All', 'Strength', 'Cardio', 'Flexibility', 'HIIT'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SB.fetchWorkouts();
    if (mounted) setState(() => _all = data.map(Workout.fromMap).toList());
  }

  List<Workout> get _filtered {
    var list = _all ?? [];
    if (_selected != 'All') list = list.where((w) => w.category == _selected).toList();
    if (_search.isNotEmpty) list = list.where((w) => w.name.toLowerCase().contains(_search)).toList();
    return list;
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Workouts')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search workouts...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              suffixIcon: _search.isNotEmpty ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
              ) : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
          child: SizedBox(height: 38, child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => CategoryChip(
              label: _categories[i],
              selected: _selected == _categories[i],
              onTap: () => setState(() => _selected = _categories[i]),
            ),
          )),
        ),
        const SizedBox(height: 16),
        Expanded(child: _all == null
          ? _LoadingGrid()
          : _filtered.isEmpty
            ? const EmptyState(emoji: '🔍', title: 'No results', subtitle: 'Try a different filter')
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.75,
                  crossAxisSpacing: 14, mainAxisSpacing: 14),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _WorkoutGridCard(workout: _filtered[i], index: i),
              ),
        ),
      ]),
    );
  }
}

class _WorkoutGridCard extends StatelessWidget {
  final Workout workout;
  final int index;
  const _WorkoutGridCard({required this.workout, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workouts/${workout.id}', extra: workout),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.bgCard),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(children: [
            Positioned.fill(child: workout.image.isNotEmpty
                ? Image.network(workout.image, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated))
                : Container(color: AppColors.bgElevated)),
            Positioned.fill(child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54])))),
            Positioned(top: 10, right: 10, child: DifficultyBadge(level: workout.difficulty)),
          ])),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(workout.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text('${workout.duration}m', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              const Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.error),
              const SizedBox(width: 3),
              Text('${workout.calories}', style: AppTextStyles.caption),
            ]),
          ])),
        ]),
      ).animate()
          .fadeIn(delay: (index * 60).ms, duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 14, mainAxisSpacing: 14),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 20),
    );
  }
}
