import 'package:fitness_app/providers/health_provider.dart';
import 'package:fitness_app/providers/nutrition_provider.dart';
import 'package:fitness_app/providers/settings_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zbjkyeziunmpdejbgbgg.supabase.co',
    publishableKey: 'sb_publishable_TjkqQ--lZ4M4cRsq_LgslQ_L0FiNSs4',
  );
  await NotificationService.init();
  final authProvider = AuthProvider();
  final healthProvider = HealthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: healthProvider),
         ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<HealthProvider, NutritionProvider>(
          create: (_) => NutritionProvider(healthProvider: healthProvider),
          update: (_, health, prev) =>
              prev ?? NutritionProvider(healthProvider: health),
        ),
      ],
      child: FitPulseApp(authProvider: authProvider),
    ),
  );
}

class FitPulseApp extends StatefulWidget {
  final AuthProvider authProvider;
  const FitPulseApp({super.key, required this.authProvider});

  @override
  State<FitPulseApp> createState() => _FitPulseAppState();
}

class _FitPulseAppState extends State<FitPulseApp> {
  late final _router = buildRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    // Watch auth so router redirect fires; also start nutrition listener
    final auth = context.watch<AuthProvider>();
    if (auth.user != null) {
      context.read<NutritionProvider>().startListening(auth.user!.id);
    }
    return MaterialApp.router(
      title: 'FitPulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
