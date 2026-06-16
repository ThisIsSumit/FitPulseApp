import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<NutritionLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final uid = SB.uid ?? '';
    SB.nutritionLogsStream(uid).listen((data) {
      if (mounted) setState(() => _logs = data.map(NutritionLog.fromMap).toList());
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayLogs = _logs.where((l) =>
      l.date.day == today.day && l.date.month == today.month && l.date.year == today.year).toList();

    final totalCals    = todayLogs.fold(0, (s, l) => s + l.calories);
    final totalProtein = todayLogs.fold(0.0, (s, l) => s + l.protein);
    final totalCarbs   = todayLogs.fold(0.0, (s, l) => s + l.carbs);
    final totalFat     = todayLogs.fold(0.0, (s, l) => s + l.fat);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [IconButton(
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          onPressed: () => _showAddMealSheet(context),
        )],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Weekly'), Tab(text: 'Meals')],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _TodayTab(logs: todayLogs, totalCals: totalCals,
            totalProtein: totalProtein, totalCarbs: totalCarbs, totalFat: totalFat,
            onAddMeal: () => _showAddMealSheet(context)),
        _WeeklyTab(logs: _logs),
        _MealsTab(logs: _logs, onAddMeal: () => _showAddMealSheet(context)),
      ]),
    );
  }

  void _showAddMealSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _AddMealSheet(),
    );
  }
}

// ─── Today Tab ────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final List<NutritionLog> logs;
  final int totalCals;
  final double totalProtein, totalCarbs, totalFat;
  final VoidCallback onAddMeal;

  const _TodayTab({required this.logs, required this.totalCals, required this.totalProtein,
      required this.totalCarbs, required this.totalFat, required this.onAddMeal});

  @override
  Widget build(BuildContext context) {
    const goalCals = 2500;
    const goalProtein = 150.0, goalCarbs = 250.0, goalFat = 80.0;

    return ListView(padding: const EdgeInsets.all(20), children: [
      // Calorie ring card
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Row(children: [
            const Text('🎯 Calorie Goal', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Text('$totalCals / $goalCals kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 80, lineWidth: 12,
            percent: (totalCals / goalCals).clamp(0.0, 1.0),
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$totalCals', style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
              const Text('kcal', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.bgSurface,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true, animationDuration: 800,
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _MacroBar(label: 'Protein', current: totalProtein, goal: goalProtein, color: AppColors.info, unit: 'g')),
            const SizedBox(width: 12),
            Expanded(child: _MacroBar(label: 'Carbs', current: totalCarbs, goal: goalCarbs, color: AppColors.warning, unit: 'g')),
            const SizedBox(width: 12),
            Expanded(child: _MacroBar(label: 'Fat', current: totalFat, goal: goalFat, color: AppColors.error, unit: 'g')),
          ]),
        ]),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

      const SizedBox(height: 24),
      SectionHeader(title: "Today's Meals", action: 'Add', onAction: onAddMeal),
      const SizedBox(height: 12),

      if (logs.isEmpty)
        EmptyState(emoji: '🍽️', title: 'No meals logged', subtitle: 'Tap + to log your first meal',
            actionLabel: 'Log Meal', onAction: onAddMeal)
      else
        ...logs.asMap().entries.map((e) => _MealTile(log: e.value, index: e.key)),
    ]);
  }
}

class _MacroBar extends StatelessWidget {
  final String label, unit;
  final double current, goal;
  final Color color;
  const _MacroBar({required this.label, required this.current, required this.goal, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Text('${current.toInt()}$unit', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (current / goal).clamp(0.0, 1.0), minHeight: 6,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
        )),
      const SizedBox(height: 4),
      Text('/ ${goal.toInt()}$unit', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }
}

class _MealTile extends StatelessWidget {
  final NutritionLog log;
  final int index;
  const _MealTile({required this.log, required this.index});

  IconData get _icon {
    switch (log.mealType.toLowerCase()) {
      case 'breakfast': return Icons.wb_sunny_outlined;
      case 'lunch':     return Icons.light_mode_outlined;
      case 'dinner':    return Icons.nights_stay_outlined;
      default:          return Icons.restaurant_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bgSurface)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: AppColors.primary, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.foodName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 3),
          Text('${log.mealType} · P:${log.protein.toInt()}g C:${log.carbs.toInt()}g F:${log.fat.toInt()}g',
              style: AppTextStyles.caption),
        ])),
        Text('${log.calories} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 350.ms).slideX(begin: 0.1, end: 0);
  }
}

// ─── Weekly Tab ───────────────────────────────────────────────
class _WeeklyTab extends StatelessWidget {
  final List<NutritionLog> logs;
  const _WeeklyTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<int, int> dayCalories = {for (var i = 0; i < 7; i++) i: 0};
    for (final l in logs) {
      final diff = now.difference(l.date).inDays;
      if (diff < 7) dayCalories[6 - diff] = (dayCalories[6 - diff] ?? 0) + l.calories;
    }

    final bars = List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: (dayCalories[i] ?? 0).toDouble(),
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.bottomCenter, end: Alignment.topCenter),
        width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
    ]));

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIdx = now.weekday - 1;
    final avgCals = dayCalories.values.fold(0, (a, b) => a + b) ~/ 7;
    final bestDay = dayCalories.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('Weekly Calorie Overview', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 24),
        Container(
          height: 220, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround, maxY: 3000,
            barGroups: bars,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.bgSurface, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, _) => Text(days[v.toInt() % 7],
                      style: TextStyle(color: v.toInt() == todayIdx ? AppColors.primary : AppColors.textMuted,
                          fontSize: 11, fontWeight: v.toInt() == todayIdx ? FontWeight.w700 : FontWeight.w400)))),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          )),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _SummaryCard(label: 'Avg Calories', value: '$avgCals', unit: 'kcal/day', color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Best Day', value: '$bestDay', unit: 'kcal', color: AppColors.warning)),
        ]),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );
}

// ─── Meals Tab ────────────────────────────────────────────────
class _MealsTab extends StatelessWidget {
  final List<NutritionLog> logs;
  final VoidCallback onAddMeal;
  const _MealsTab({required this.logs, required this.onAddMeal});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return EmptyState(emoji: '🥗', title: 'No meals logged yet',
        subtitle: 'Start tracking your nutrition', actionLabel: 'Log Meal', onAction: onAddMeal);
    final grouped = <String, List<NutritionLog>>{};
    for (final l in logs) grouped.putIfAbsent(l.mealType, () => []).add(l);
    return ListView(padding: const EdgeInsets.all(20),
        children: grouped.entries.map((e) => _MealGroup(type: e.key, logs: e.value)).toList());
  }
}

class _MealGroup extends StatelessWidget {
  final String type;
  final List<NutritionLog> logs;
  const _MealGroup({required this.type, required this.logs});

  @override
  Widget build(BuildContext context) {
    final total = logs.fold(0, (s, l) => s + l.calories);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(type, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        Text('$total kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      ...logs.asMap().entries.map((e) => _MealTile(log: e.value, index: e.key)),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Add Meal Sheet ───────────────────────────────────────────
class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();
  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _foodCtrl    = TextEditingController();
  final _calCtrl     = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl   = TextEditingController();
  final _fatCtrl     = TextEditingController();
  String _mealType   = 'Breakfast';
  bool _loading      = false;
  final _meals       = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _foodCtrl.dispose(); _calCtrl.dispose();
    _proteinCtrl.dispose(); _carbsCtrl.dispose(); _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_foodCtrl.text.isEmpty || _calCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await SB.logMeal({
      'food_name': _foodCtrl.text.trim(),
      'meal_type': _mealType,
      'calories': int.tryParse(_calCtrl.text) ?? 0,
      'protein': double.tryParse(_proteinCtrl.text) ?? 0,
      'carbs': double.tryParse(_carbsCtrl.text) ?? 0,
      'fat': double.tryParse(_fatCtrl.text) ?? 0,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Log Meal', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 20),
        Wrap(spacing: 8, children: _meals.map((m) => ChoiceChip(
          label: Text(m),
          selected: _mealType == m,
          onSelected: (_) => setState(() => _mealType = m),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
              color: _mealType == m ? AppColors.bgDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600),
        )).toList()),
        const SizedBox(height: 16),
        AppTextField(controller: _foodCtrl, label: 'Food Name', hint: 'e.g. Chicken Rice Bowl'),
        const SizedBox(height: 12),
        AppTextField(controller: _calCtrl, label: 'Calories', hint: '450', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: _proteinCtrl, label: 'Protein (g)', keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: AppTextField(controller: _carbsCtrl, label: 'Carbs (g)', keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: AppTextField(controller: _fatCtrl, label: 'Fat (g)', keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 20),
        GradientButton(label: 'Save Meal', onTap: _save, isLoading: _loading),
      ]),
    );
  }
}
