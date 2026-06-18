import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/workout/workouts_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/active_workout_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/community/create_post_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../models/models.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/onboarding',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final loc = state.matchedLocation;
      final publicRoutes = [
        '/onboarding',
        '/login',
        '/signup',
        '/forgot-password'
      ];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));
      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/workouts/:id/active',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final workout = state.extra as Workout?;
          if (workout == null) {
            // extra was lost (e.g. during a go() transition away from this route) — bounce home safely
            return const _RedirectToHome();
          }
          return ActiveWorkoutScreen(workout: workout);
        },
      ),
      GoRoute(
        path: '/community/post/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final post = state.extra as Post?;
          if (post == null) return const _RedirectToHome();
          return PostDetailScreen(post: post);
        },
      ),
      GoRoute(
        path: '/community/create-post',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,

       builder: (context, state) {
    final user = state.extra as AppUser;
    return SettingsScreen(user: user);
  },
      ),

      // Shell
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/workouts',
            builder: (_, __) => const WorkoutsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) {
                  final workout = state.extra as Workout?;
                  if (workout == null) return const _RedirectToHome();
                  return WorkoutDetailScreen(workout: workout);
                },
              ),
            ],
          ),
          GoRoute(
              path: '/nutrition', builder: (_, __) => const NutritionScreen()),
          GoRoute(
              path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}

class _RedirectToHome extends StatefulWidget {
  const _RedirectToHome();
  @override
  State<_RedirectToHome> createState() => _RedirectToHomeState();
}

class _RedirectToHomeState extends State<_RedirectToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
}
