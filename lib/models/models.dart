// ─── User / Profile ─────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;
  final int totalWorkouts;
  final int totalCaloriesBurned;
  final int streak;
  final int level;
  final int xp;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.bio = '',
    this.followers = const [],
    this.following = const [],
    this.totalWorkouts = 0,
    this.totalCaloriesBurned = 0,
    this.streak = 0,
    this.level = 1,
    this.xp = 0,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        photoUrl: m['photo_url'] ?? '',
        bio: m['bio'] ?? '',
        followers: List<String>.from(m['followers'] ?? []),
        following: List<String>.from(m['following'] ?? []),
        totalWorkouts: m['total_workouts'] ?? 0,
        totalCaloriesBurned: m['total_calories_burned'] ?? 0,
        streak: m['streak'] ?? 0,
        level: m['level'] ?? 1,
        xp: m['xp'] ?? 0,
      );

  int get xpToNextLevel => level * 500;
  double get xpProgress => (xp / xpToNextLevel).clamp(0.0, 1.0);
}

// ─── Exercise ────────────────────────────────────────────────
class Exercise {
  final String name;
  final int sets;
  final int reps;
  final int rest;
  bool completed;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    this.completed = false,
  });

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
        name: m['name'] ?? '',
        sets: m['sets'] ?? 0,
        reps: m['reps'] ?? 0,
        rest: m['rest'] ?? 0,
      );
}

// ─── Workout ─────────────────────────────────────────────────
class Workout {
  final String id;
  final String name;
  final String category;
  final String difficulty;
  final int duration;
  final int calories;
  final String image;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.calories,
    required this.image,
    required this.exercises,
  });

  factory Workout.fromMap(Map<String, dynamic> m) => Workout(
        id: m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        difficulty: m['difficulty'] ?? '',
        duration: m['duration'] ?? 0,
        calories: m['calories'] ?? 0,
        image: m['image'] ?? '',
        exercises: (m['exercises'] as List<dynamic>? ?? [])
            .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Post ────────────────────────────────────────────────────
class Post {
  final String id;
  final String uid;
  final String text;
  final String? imageUrl;
  final String type;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final Map<String, dynamic> userInfo;

  Post({
    required this.id,
    required this.uid,
    required this.text,
    this.imageUrl,
    this.type = 'Achievement',
    this.likes = const [],
    this.commentsCount = 0,
    required this.createdAt,
    required this.userInfo,
  });

  factory Post.fromMap(Map<String, dynamic> m) => Post(
        id: m['id']?.toString() ?? '',
        uid: m['uid'] ?? '',
        text: m['text'] ?? '',
        imageUrl: m['image_url'],
        type: m['type'] ?? 'Achievement',
        likes: List<String>.from(m['likes'] ?? []),
        commentsCount: m['comments_count'] ?? 0,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'])
            : DateTime.now(),
        userInfo: Map<String, dynamic>.from(m['user_info'] ?? {}),
      );

  bool isLikedBy(String uid) => likes.contains(uid);
}

// ─── Challenge ───────────────────────────────────────────────
class Challenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int duration;
  final List<String> participants;
  final int target;
  final String unit;
  final String reward;
  final DateTime startDate;
  final DateTime endDate;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.duration,
    required this.participants,
    required this.target,
    required this.unit,
    required this.reward,
    required this.startDate,
    required this.endDate,
  });

  factory Challenge.fromMap(Map<String, dynamic> m) => Challenge(
        id: m['id']?.toString() ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        icon: m['icon'] ?? '🏋',
        category: m['category'] ?? '',
        duration: m['duration'] ?? 0,
        participants: List<String>.from(m['participants'] ?? []),
        target: m['target'] ?? 0,
        unit: m['unit'] ?? '',
        reward: m['reward'] ?? '',
        startDate: m['start_date'] != null
            ? DateTime.parse(m['start_date'])
            : DateTime.now(),
        endDate: m['end_date'] != null
            ? DateTime.parse(m['end_date'])
            : DateTime.now(),
      );

  bool isJoined(String uid) => participants.contains(uid);

  int get daysLeft {
    final d = endDate.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }
}

// ─── Nutrition Log ───────────────────────────────────────────
class NutritionLog {
  final String id;
  final String uid;
  final String mealType;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;

  NutritionLog({
    required this.id,
    required this.uid,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
  });

  factory NutritionLog.fromMap(Map<String, dynamic> m) => NutritionLog(
        id: m['id']?.toString() ?? '',
        uid: m['uid'] ?? '',
        mealType: m['meal_type'] ?? '',
        foodName: m['food_name'] ?? '',
        calories: m['calories'] ?? 0,
        protein: (m['protein'] ?? 0).toDouble(),
        carbs: (m['carbs'] ?? 0).toDouble(),
        fat: (m['fat'] ?? 0).toDouble(),
        date: m['created_at'] != null
            ? DateTime.parse(m['created_at'])
            : DateTime.now(),
      );
}

// ─── Workout Log ─────────────────────────────────────────────
class WorkoutLog {
  final String id;
  final String uid;
  final String workoutName;
  final int duration;
  final int calories;
  final DateTime date;

  WorkoutLog({
    required this.id,
    required this.uid,
    required this.workoutName,
    required this.duration,
    required this.calories,
    required this.date,
  });

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
        id: m['id']?.toString() ?? '',
        uid: m['uid'] ?? '',
        workoutName: m['workout_name'] ?? '',
        duration: m['duration'] ?? 0,
        calories: m['calories'] ?? 0,
        date: m['created_at'] != null
            ? DateTime.parse(m['created_at'])
            : DateTime.now(),
      );
}
