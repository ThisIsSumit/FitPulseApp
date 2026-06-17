import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'utils/router.dart';

// ── Replace with your actual Supabase project values ──────────────────────
// const _supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
// const _supabaseAnonKey = 'YOUR_ANON_KEY';
// ──────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zbjkyeziunmpdejbgbgg.supabase.co',
    publishableKey: 'sb_publishable_TjkqQ--lZ4M4cRsq_LgslQ_L0FiNSs4',
  );
  final authprovider = AuthProvider();
  runApp(ChangeNotifierProvider.value(
      value: authprovider, child:  FitPulseApp(provider: authprovider)));
}

class FitPulseApp extends StatefulWidget {
  final AuthProvider provider;
  const FitPulseApp({super.key, required this.provider});

  @override
  State<FitPulseApp> createState() => _FitPulseAppState();
}

class _FitPulseAppState extends State<FitPulseApp> {
  // Router created ONCE in State — never recreated on rebuild.
  // This is what prevents the GlobalKey clash on home screen.
  late final _router = buildRouter(widget.provider);

  @override
  Widget build(BuildContext context) {
    // Still watch so GoRouter's refreshListenable triggers
    // login/logout redirects — but _router itself is not recreated.
    context.watch<AuthProvider>();
    return MaterialApp.router(
      title: 'FitPulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}


