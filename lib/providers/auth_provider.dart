// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    print('🔵 AuthProvider initialized');

    // Listen to Supabase auth state changes
    SB.authStream.listen((event) async {
      print('🟡 Auth State Changed');
      print('   Event: ${event.event}');
      print('   Session Exists: ${event.session != null}');

      if (event.session != null) {
        print('   User ID: ${event.session!.user.id}');
        print('   Email: ${event.session!.user.email}');
      }

      if (event.event == AuthChangeEvent.signedOut) {
        print('🔴 User signed out');
        _user = null;
        notifyListeners();
      } else if (event.session != null) {
        print('🟢 Loading profile after auth change...');
        await _loadProfile(event.session!.user.id);
      }
    });

    // Load current session on startup
    final session = SB.auth.currentSession;

    print('🟠 Checking existing session...');
    print('   Session Exists: ${session != null}');

    if (session != null) {
      print('🟢 Existing session found');
      print('   User ID: ${session.user.id}');
      print('   Email: ${session.user.email}');
      _loadProfile(session.user.id);
    }
  }

  Future<void> _loadProfile(String id) async {
    print('🔵 Loading profile...');
    print('   User ID: $id');

    try {
      final data = await SB.fetchProfile(id);

      print('📦 Profile Data: $data');

      if (data != null) {
        _user = AppUser.fromMap(data);

        print('✅ Profile loaded successfully');
        print('   Name: ${_user?.name}');
        print('   Email: ${_user?.email}');

        notifyListeners();
      } else {
        print('⚠️ No profile found for user');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading profile');
      print('   Error: $e');
      print(stackTrace);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    print('🟢 SIGN UP STARTED');
    print('   Name: $name');
    print('   Email: $email');

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await SB.signUp(
        email: email,
        password: password,
        name: name,
      );
      print('📦 Sign Up Response: $res');
      print('✅ Sign Up Response');
      print('   User: ${res.user}');
      print('   User ID: ${res.user?.id}');

      if (res.user != null) {
        await _loadProfile(res.user!.id);
      }

      _loading = false;
      notifyListeners();

      return res.user != null;
    } on AuthException catch (e) {
      print('❌ AuthException during sign up');
      print('   Message: ${e.message}');

      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('❌ Unknown error during sign up');
      print('   Error: $e');
      print(stackTrace);

      _error = 'Something went wrong. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    print('🟢 SIGN IN STARTED');
    print('   Email: $email');

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await SB.signIn(
        email: email,
        password: password,
      );

      print('✅ Sign In Response');
      print('   User: ${res.user}');
      print('   User ID: ${res.user?.id}');

      if (res.user != null) {
        await _loadProfile(res.user!.id);
      }

      _loading = false;
      notifyListeners();

      return res.user != null;
    } on AuthException catch (e) {
      print('❌ AuthException during sign in');
      print('   Message: ${e.message}');

      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('❌ Unknown error during sign in');
      print('   Error: $e');
      print(stackTrace);

      _error = 'Something went wrong. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    print('🔴 SIGN OUT STARTED');

    try {
      await SB.signOut();

      print('✅ Sign out successful');

      _user = null;
      notifyListeners();
    } catch (e) {
      print('❌ Sign out failed');
      print('   Error: $e');
    }
  }

  Future<void> refreshUser() async {
    final id = SB.uid;

    print('🔄 Refreshing user');
    print('   User ID: $id');

    if (id != null) {
      await _loadProfile(id);
    } else {
      print('⚠️ No logged in user found');
    }
  }

  void clearError() {
    print('🧹 Clearing error: $_error');

    _error = null;
    notifyListeners();
  }
}
