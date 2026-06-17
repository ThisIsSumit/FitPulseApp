
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import 'health_provider.dart';

class NutritionProvider extends ChangeNotifier {
  final HealthProvider healthProvider;
  List<NutritionLog> _logs = [];
  bool _loading = false;

  List<NutritionLog> get logs => _logs;
  bool get loading => _loading;

  List<NutritionLog> get todayLogs {
    final today = DateTime.now();
    return _logs.where((l) =>
        l.date.day == today.day &&
        l.date.month == today.month &&
        l.date.year == today.year).toList();
  }

  int get todayCalories => todayLogs.fold(0, (s, l) => s + l.calories);
  double get todayProtein => todayLogs.fold(0.0, (s, l) => s + l.protein);
  double get todayCarbs   => todayLogs.fold(0.0, (s, l) => s + l.carbs);
  double get todayFat     => todayLogs.fold(0.0, (s, l) => s + l.fat);

  NutritionProvider({required this.healthProvider});

  void startListening(String uid) {
    SB.nutritionLogsStream(uid).listen((data) {
      _logs = data.map(NutritionLog.fromMap).toList();
      // Push today's totals into HealthProvider so home screen stays in sync
      healthProvider.updateNutrition(
        calories: todayCalories,
        protein: todayProtein,
        carbs: todayCarbs,
        fat: todayFat,
      );
      notifyListeners();
    });
  }

  Future<void> logMeal(Map<String, dynamic> data) async {
    await SB.logMeal(data);
    // Stream will auto-update via listener above
  }
}
