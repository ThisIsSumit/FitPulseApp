import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF00E5A0);       // Electric mint green
  static const Color primaryDark = Color(0xFF00B87A);
  static const Color secondary = Color(0xFF7B61FF);      // Electric violet
  static const Color accent = Color(0xFFFF6B35);         // Energy orange

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF13131A);
  static const Color bgElevated = Color(0xFF1A1A26);
  static const Color bgSurface = Color(0xFF22223A);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF555570);

  // Status
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB830);
  static const Color error = Color(0xFFFF4466);
  static const Color info = Color(0xFF44AAFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A26), Color(0xFF13131A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFFAA44FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3080)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bgCard,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineLarge,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: AppTextStyles.bodyMedium,
      hintStyle: AppTextStyles.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgElevated,
      labelStyle: AppTextStyles.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    ),
  );
}
