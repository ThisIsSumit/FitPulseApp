import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Single entry-point for all Supabase operations.
class SB {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

  static String? get uid => auth.currentUser?.id;
  static User? get currentUser => auth.currentUser;

  // ─── Auth ──────────────────────────────────────────────────────────────
  static Stream<AuthState> get authStream => auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'photo_url': '', 'bio': ''},
    );
    if (res.user != null) {
      // Insert profile row (trigger also does this, but belt-and-braces)
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'name': name,
        'email': email,
        'photo_url': '',
        'bio': '',
        'followers': [],
        'following': [],
        'total_workouts': 0,
        'total_calories_burned': 0,
        'streak': 0,
        'level': 1,
        'xp': 0,
      });
      await seedWorkoutsIfEmpty();
      await seedChallengesIfEmpty();
    }
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => auth.signOut();

  static Future<void> resetPassword(String email) =>
      auth.resetPasswordForEmail(email);

  // ─── Profiles ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchProfile(String id) async {
    final res =
        await client.from('profiles').select().eq('id', id).maybeSingle();
    return res;
  }

  static Stream<Map<String, dynamic>> profileStream(String id) =>
      client.from('profiles').stream(primaryKey: ['id']).eq('id', id).map(
            (rows) => rows.isNotEmpty ? rows.first : <String, dynamic>{},
          );

  static Future<void> updateProfile(String id, Map<String, dynamic> data) =>
      client.from('profiles').update(data).eq('id', id);

  static Future<String> uploadAvatar(String id, File file) async {
    final path = '$id/avatar.jpg';
    try {
      await storage.from('avatars').upload(
            path,
            file,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
    } catch (e) {
      print(e);
    }
    final url = storage.from('avatars').getPublicUrl(path);
    await updateProfile(id, {'photo_url': url});
    return url;
  }

  // ─── Workouts ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchWorkouts() =>
      client.from('workouts').select().order('created_at');

  // ─── Workout Logs ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchWorkoutLogs(String uid) =>
      client
          .from('workout_logs')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(30);

  static Stream<List<Map<String, dynamic>>> workoutLogsStream(String uid) =>
      client
          .from('workout_logs')
          .stream(primaryKey: ['id'])
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(30);

  static Future<void> logWorkout(Map<String, dynamic> data) =>
      client.from('workout_logs').insert({
        ...data,
        'uid': uid,
        'created_at': DateTime.now().toIso8601String(),
      });

  // ─── Nutrition ────────────────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> nutritionLogsStream(String uid) =>
      client
          .from('nutrition_logs')
          .stream(primaryKey: ['id'])
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(60);

  static Future<void> logMeal(Map<String, dynamic> data) =>
      client.from('nutrition_logs').insert({
        ...data,
        'uid': uid,
        'created_at': DateTime.now().toIso8601String(),
      });

  // ─── Posts ────────────────────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> postsStream() => client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(50);

  static Future<Map<String, dynamic>> createPost(
      Map<String, dynamic> data) async {
    final res = await client
        .from('posts')
        .insert({
          ...data,
          'uid': uid,
          'likes': [],
          'comments_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return res;
  }

  static Future<bool> toggleFollow(String targetUid) async {
    final result =
        await client.rpc('toggle_follow', params: {'target_uid': targetUid});
    return result as bool;
  }

  static Future<
      Map<String,
          dynamic>?> fetchPublicProfile(String uid) => fetchProfile(
      uid); // reuses existing method — profiles are already readable by all authenticated users

  static Stream<Map<String, dynamic>> publicProfileStream(String uid) =>
      profileStream(uid);
  static Future<void> toggleLike(
      String postId, List<String> currentLikes) async {
    final me = uid!;
    final updated = currentLikes.contains(me)
        ? (List<String>.from(currentLikes)..remove(me))
        : (List<String>.from(currentLikes)..add(me));
    await client.from('posts').update({'likes': updated}).eq('id', postId);
  }

  static Stream<List<Map<String, dynamic>>> commentsStream(String postId) =>
      client
          .from('comments')
          .stream(primaryKey: ['id'])
          .eq('post_id', postId)
          .order('created_at');

  static Future<void> addComment({
    required String postId,
    required String text,
    required Map<String, dynamic> userInfo,
  }) async {
    await client.from('comments').insert({
      'post_id': postId,
      'uid': uid,
      'text': text,
      'user_info': userInfo,
      'created_at': DateTime.now().toIso8601String(),
    });
    await client.rpc('increment_comments', params: {'post_id': postId});
  }

  static Future<String?> uploadPostImage(File file) async {
    try {
      final path = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await storage.from('post-images').upload(
            path,
            file,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      final url = storage.from('post-images').getPublicUrl(path);
      return url;
    } catch (e) {
      print('❌ Image upload failed: $e');
      return null;
    }
  }

  // ─── Challenges ───────────────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> challengesStream() =>
      client.from('challenges').stream(primaryKey: ['id']).order('start_date');

  static Future<void> joinChallenge(
      String challengeId, List<String> current) async {
    final me = uid!;
    if (current.contains(me)) return;
    await client.from('challenges').update({
      'participants': [...current, me],
    }).eq('id', challengeId);
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchLeaderboard() => client
      .from('profiles')
      .select()
      .order('total_calories_burned', ascending: false)
      .limit(20);

  static Stream<List<Map<String, dynamic>>> leaderboardStream() => client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .order('total_calories_burned', ascending: false)
      .limit(20);

  // ─── Increment helpers ────────────────────────────────────────────────
  static Future<void> incrementProfileStats({
    required String id,
    int workouts = 0,
    int calories = 0,
    int xp = 0,
  }) async {
    await client.rpc('increment_profile_stats', params: {
      'p_id': id,
      'p_workouts': workouts,
      'p_calories': calories,
      'p_xp': xp,
    });
  }

  static Future<void> deletePost(String postId, {String? imageUrl}) async {
    // Delete the image from storage first (cleanup), if one exists
    if (imageUrl != null && imageUrl.contains('post-images')) {
      try {
        final fileName = imageUrl.split('/').last;
        await storage.from('post-images').remove([fileName]);
      } catch (_) {
        // Non-fatal — proceed with post deletion even if image cleanup fails
      }
    }
    await client.from('posts').delete().eq('id', postId);
  }

  static Future<void> updatePost({
    required String postId,
    required String text,
    required String type,
    String? imageUrl,
  }) async {
    await client.from('posts').update({
      'text': text,
      'type': type,
      'image_url': imageUrl,
    }).eq('id', postId);
  }

  // ─── Seed Data ────────────────────────────────────────────────────────
  static Future<void> seedWorkoutsIfEmpty() async {
    final existing = await client.from('workouts').select('id').limit(1);
    if ((existing as List).isNotEmpty) return;

    final workouts = [
      {
        'name': 'Full Body Blast',
        'category': 'Strength',
        'difficulty': 'Intermediate',
        'duration': 45,
        'calories': 380,
        'image':
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
        'exercises': [
          {'name': 'Push-ups', 'sets': 4, 'reps': 15, 'rest': 60},
          {'name': 'Squats', 'sets': 4, 'reps': 20, 'rest': 60},
          {'name': 'Deadlifts', 'sets': 3, 'reps': 12, 'rest': 90},
          {'name': 'Pull-ups', 'sets': 3, 'reps': 10, 'rest': 90},
          {'name': 'Plank', 'sets': 3, 'reps': 60, 'rest': 45},
        ],
      },
      {
        'name': 'HIIT Cardio Rush',
        'category': 'Cardio',
        'difficulty': 'Advanced',
        'duration': 30,
        'calories': 450,
        'image':
            'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400',
        'exercises': [
          {'name': 'Burpees', 'sets': 4, 'reps': 10, 'rest': 30},
          {'name': 'High Knees', 'sets': 4, 'reps': 30, 'rest': 30},
          {'name': 'Jump Rope', 'sets': 5, 'reps': 60, 'rest': 20},
          {'name': 'Box Jumps', 'sets': 3, 'reps': 12, 'rest': 45},
          {'name': 'Mountain Climbers', 'sets': 4, 'reps': 20, 'rest': 30},
        ],
      },
      {
        'name': 'Yoga Flow',
        'category': 'Flexibility',
        'difficulty': 'Beginner',
        'duration': 40,
        'calories': 180,
        'image':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
        'exercises': [
          {'name': 'Sun Salutation', 'sets': 3, 'reps': 5, 'rest': 30},
          {'name': 'Warrior Pose', 'sets': 2, 'reps': 60, 'rest': 20},
          {'name': 'Tree Pose', 'sets': 2, 'reps': 45, 'rest': 20},
          {'name': 'Pigeon Pose', 'sets': 2, 'reps': 60, 'rest': 30},
          {'name': "Child's Pose", 'sets': 1, 'reps': 300, 'rest': 0},
        ],
      },
      {
        'name': 'Core Crusher',
        'category': 'Strength',
        'difficulty': 'Intermediate',
        'duration': 25,
        'calories': 220,
        'image':
            'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=400',
        'exercises': [
          {'name': 'Crunches', 'sets': 4, 'reps': 25, 'rest': 30},
          {'name': 'Leg Raises', 'sets': 3, 'reps': 20, 'rest': 40},
          {'name': 'Russian Twists', 'sets': 4, 'reps': 20, 'rest': 30},
          {'name': 'Bicycle Crunches', 'sets': 3, 'reps': 30, 'rest': 30},
          {'name': 'Ab Wheel Rollout', 'sets': 3, 'reps': 12, 'rest': 60},
        ],
      },
      {
        'name': 'Upper Body Power',
        'category': 'Strength',
        'difficulty': 'Advanced',
        'duration': 50,
        'calories': 340,
        'image':
            'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
        'exercises': [
          {'name': 'Bench Press', 'sets': 5, 'reps': 8, 'rest': 120},
          {'name': 'Overhead Press', 'sets': 4, 'reps': 10, 'rest': 90},
          {'name': 'Bent-over Rows', 'sets': 4, 'reps': 12, 'rest': 90},
          {'name': 'Dips', 'sets': 3, 'reps': 15, 'rest': 60},
          {'name': 'Bicep Curls', 'sets': 3, 'reps': 15, 'rest': 60},
        ],
      },
      {
        'name': 'Morning Stretch',
        'category': 'Flexibility',
        'difficulty': 'Beginner',
        'duration': 15,
        'calories': 80,
        'image':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
        'exercises': [
          {'name': 'Neck Rolls', 'sets': 2, 'reps': 10, 'rest': 15},
          {'name': 'Shoulder Stretch', 'sets': 2, 'reps': 30, 'rest': 15},
          {'name': 'Hip Circles', 'sets': 2, 'reps': 10, 'rest': 15},
          {'name': 'Forward Fold', 'sets': 3, 'reps': 30, 'rest': 15},
          {"name": "Child's Pose", 'sets': 2, 'reps': 60, 'rest': 0},
        ],
      },
    ];
    await client.from('workouts').insert(workouts);
  }

  static Future<void> seedChallengesIfEmpty() async {
    final existing = await client.from('challenges').select('id').limit(1);
    if ((existing as List).isNotEmpty) return;

    final now = DateTime.now();
    await client.from('challenges').insert([
      {
        'title': '30-Day Pushup Challenge',
        'description': 'Complete 100 pushups daily for 30 days',
        'icon': '💪',
        'category': 'Strength',
        'duration': 30,
        'participants': [],
        'target': 3000,
        'unit': 'pushups',
        'reward': '500 XP + Gold Badge',
        'start_date': now.toIso8601String(),
        'end_date': now.add(const Duration(days: 30)).toIso8601String(),
      },
      {
        'title': 'Marathon Prep',
        'description': 'Run 200km in 30 days',
        'icon': '🏃',
        'category': 'Cardio',
        'duration': 30,
        'participants': [],
        'target': 200,
        'unit': 'km',
        'reward': '1000 XP + Marathon Badge',
        'start_date': now.toIso8601String(),
        'end_date': now.add(const Duration(days: 30)).toIso8601String(),
      },
      {
        'title': 'Flexibility Week',
        'description': 'Stretch for 20 mins every day for 7 days',
        'icon': '🧘',
        'category': 'Flexibility',
        'duration': 7,
        'participants': [],
        'target': 140,
        'unit': 'minutes',
        'reward': '200 XP + Flexibility Badge',
        'start_date': now.toIso8601String(),
        'end_date': now.add(const Duration(days: 7)).toIso8601String(),
      },
    ]);
  }
}
