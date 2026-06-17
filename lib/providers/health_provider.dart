
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProvider extends ChangeNotifier {
  // ── Steps ─────────────────────────────────────────────────
  int _steps = 0;
  int _stepGoal = 10000;
  int _baseSteps = 0; // steps at start of day (to compute today's count)
  bool _stepAvailable = false;

  int get steps => _steps;
  int get stepGoal => _stepGoal;
  bool get stepAvailable => _stepAvailable;
  double get stepProgress => (_steps / _stepGoal).clamp(0.0, 1.0);
  int get stepCalories => (_steps * 0.04).toInt(); // ~0.04 kcal per step

  // ── Today nutrition (set by NutritionProvider) ────────────
  int _todayCaloriesConsumed = 0;
  double _todayProtein = 0;
  double _todayCarbs = 0;
  double _todayFat = 0;
  int _calorieGoal = 2500;

  int get todayCaloriesConsumed => _todayCaloriesConsumed;
  double get todayProtein => _todayProtein;
  double get todayCarbs => _todayCarbs;
  double get todayFat => _todayFat;
  int get calorieGoal => _calorieGoal;
  double get calorieProgress =>
      (_todayCaloriesConsumed / _calorieGoal).clamp(0.0, 1.0);
  int get caloriesRemaining =>
      (_calorieGoal - _todayCaloriesConsumed).clamp(0, _calorieGoal);

  // ── Today workout calories burned (set externally) ────────
  int _todayCaloriesBurned = 0;
  int get todayCaloriesBurned => _todayCaloriesBurned;

  HealthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadPrefs();
    await _initPedometer();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _stepGoal = p.getInt('step_goal') ?? 10000;
    _calorieGoal = p.getInt('calorie_goal') ?? 2500;
    // Restore today's base so steps survive restarts within same day
    final savedDate = p.getString('step_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == today) {
      _baseSteps = p.getInt('step_base') ?? 0;
    } else {
      // New day — reset base on next pedometer reading
      _baseSteps = -1;
      await p.setString('step_date', today);
    }
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;

    _stepAvailable = true;
    Pedometer.stepCountStream.listen(_onStep, onError: (_) {
      _stepAvailable = false;
      notifyListeners();
    });
  }

  void _onStep(StepCount event) async {
    final raw = event.steps;
    if (_baseSteps == -1) {
      // First reading of the day — calibrate base
      _baseSteps = raw;
      final p = await SharedPreferences.getInstance();
      await p.setInt('step_base', _baseSteps);
    }
    _steps = (raw - _baseSteps).clamp(0, 999999);
    notifyListeners();
  }

  // Called by NutritionProvider when logs update
  void updateNutrition({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    _todayCaloriesConsumed = calories;
    _todayProtein = protein;
    _todayCarbs = carbs;
    _todayFat = fat;
    notifyListeners();
  }

  // Called after a workout is completed
  void addBurnedCalories(int cal) {
    _todayCaloriesBurned += cal;
    notifyListeners();
  }

  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    final p = await SharedPreferences.getInstance();
    await p.setInt('step_goal', goal);
    notifyListeners();
  }

  Future<void> setCalorieGoal(int goal) async {
    _calorieGoal = goal;
    final p = await SharedPreferences.getInstance();
    await p.setInt('calorie_goal', goal);
    notifyListeners();
  }
}
