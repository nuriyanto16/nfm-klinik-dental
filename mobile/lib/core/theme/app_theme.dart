import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF81C784);

  static const Color pink = Color(0xFFEC407A);
  static const Color pinkAccent = Color(0xFFFF4081);
  static const Color pinkDark = Color(0xFFD81B60);

  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMuted = Color(0xFF718096);
  
  static Color getPrimary(AppThemeColor themeColor) {
    switch (themeColor) {
      case AppThemeColor.blue:
        return const Color(0xFF2563EB); // Tailwind Blue 600
      case AppThemeColor.pink:
        return const Color(0xFFEC407A); // Existing Pink
      case AppThemeColor.emerald:
        return const Color(0xFF10B981); // Tailwind Emerald 500
      case AppThemeColor.violet:
        return const Color(0xFF8B5CF6); // Tailwind Violet 500
    }
  }

  static Color getPrimaryLight(AppThemeColor themeColor) {
    switch (themeColor) {
      case AppThemeColor.blue:
        return const Color(0xFF60A5FA); // Tailwind Blue 400
      case AppThemeColor.pink:
        return const Color(0xFFF48FB1); // Lighter Pink
      case AppThemeColor.emerald:
        return const Color(0xFF34D399); // Tailwind Emerald 400
      case AppThemeColor.violet:
        return const Color(0xFFA78BFA); // Tailwind Violet 400
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light(ThemeState state) => _base(state: state);
  
  static ThemeData dark(ThemeState state) => _base(state: state);

  static ThemeData _base({required ThemeState state}) {
    final primary = AppColors.getPrimary(state.colorTheme);
    final secondary = AppColors.pink;
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
    );

    final baseTextTheme = GoogleFonts.getTextTheme(
      state.fontFamily,
      ThemeData(brightness: state.isDarkMode ? Brightness.dark : Brightness.light).textTheme,
    ).copyWith(
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      titleLarge: const TextStyle(fontWeight: FontWeight.bold),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: state.isDarkMode ? const Color(0xFF1A202C) : AppColors.bgLight,
      splashFactory: InkRipple.splashFactory,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.getFont(state.fontFamily, color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: state.isDarkMode ? const Color(0xFF2D3748) : AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: state.isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: state.isDarkMode ? const Color(0xFF2D3748) : Colors.white,
        selectedColor: secondary,
        secondarySelectedColor: primary,
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: state.isDarkMode ? Colors.white : AppColors.textDark),
        side: BorderSide(color: state.isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.getFont(state.fontFamily, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.getFont(state.fontFamily, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: AppColors.pink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.getFont(state.fontFamily, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: state.isDarkMode ? const Color(0xFF2D3748) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: state.isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFCBD5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: state.isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2.0),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: state.isDarkMode ? const Color(0xFF2D3748) : Colors.white,
        indicatorColor: primary.withOpacity(0.15),
        elevation: 8,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(color: state.isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFEDF2F7), space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
